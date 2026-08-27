//! A plugin to prevent/resolve jamming rigidbodies, by ensuring zero
//! jamming before drawing the scene.
//! NOTE: It depends on the collision-detector plugin.
//! And on the rigibody script as well.
//!
//! You shall embed it in the lifecycle of the scene "postUpdate":
//! ```
//! var scene = zigsdl.modules.Scene.init(allocator);
//! defer scene.deinit();
//!
//! scene.lifecycle.postUpdate = struct {
//!     var jr: ?*zigsdl.plugins.JammingResolver = null;
//!     fn func(_: *anyopaque) void {
//!         jr = jr orelse zigsdl.modules.PluginManager.get(zigsdl.plugins.JammingResolver, "JammingResolver").?;
//!         jr.?.resolve();
//!     }
//! }.func;
//! ```

const std = @import("std");
const PluginManager = @import("../modules/plugin-manager.zig");
const CollisionDetector = @import("./collision-detector.zig");
const Object = @import("../modules/object.zig");
const Collision = @import("../types/collision.zig");
const Vector = @import("../types/vector.zig");
const Rigidbody = @import("../scripts/rigidbody.zig");

const JammingResolver = @This();

/// A list of subscribed objects to prevent jamming amongst.
_objects: std.ArrayList(*Object) = .empty,

_collisionDetector: *CollisionDetector,
_allocator: std.mem.Allocator,

/// Just a buffer for the resolve method to use.
_collisions: std.ArrayList(Collision) = .empty,

pub fn init(allocator: std.mem.Allocator) !JammingResolver {
    if (PluginManager.isInitialized() == false) return error.PluginManagerRequired;
    if (PluginManager.get(CollisionDetector, "CollisionDetector")) |cd| {
        return .{
            ._collisionDetector = cd,
            ._allocator = allocator,
        };
    }
    return error.CollisionDetectorPluginRequired;
}

pub fn deinit(self: *JammingResolver) void {
    self._objects.deinit(self._allocator);
    self._collisions.deinit(self._allocator);
}

/// Add object to the collection in which jamming shall be resolved.
/// NOTE: object must carry the rigidbody script.
pub fn addObject(self: *JammingResolver, obj: *Object) !void {
    if (obj.getScript(Rigidbody, "Rigidbody") == null) {
        std.log.err("JammingResolver.addObject: added objects must contain the Rigidbody script.", .{});
        return error.RigidbodyRequired;
    }
    try self._objects.append(self._allocator, obj);
}

/// Remove object from the collection in which the jamming shall be resolved.
pub fn rmvObject(self: *JammingResolver, obj: *Object) void {
    var index: ?usize = null;
    for (self._objects.items, 0..) |o, i| {
        if (o == obj) {
            index = i;
            break;
        }
    }
    if (index) |i| _ = self._objects.orderedRemove(i);
}

pub fn resolve(self: *JammingResolver, refreshCollisions: bool) void {
    const dc = self._collisionDetector;
    if (refreshCollisions) dc.detectCollision();

    for (self._objects.items) |obj1| {
        self._collisions.clearRetainingCapacity();
        dc.getCollisions(self._allocator, obj1, &self._collisions) catch {
            std.log.err("JammingResolver.resolve: collisions couldn't be detected!", .{});
            return;
        };

        // - Get the negative momentum which shall be used in order to get the
        //   original positions of the object face points.
        const rigid1 = obj1.getScript(Rigidbody, "Rigidbody").?;
        const nmom = rigid1.velocity.multiply(-1);
        const pos1 = obj1.position.add(nmom);

        // - Get the minimal magnitude to move pos1 so that it barely touches `collision.face`.
        var min_mag: ?f32 = null;
        for (self._collisions.items) |col| {
            for (col.cps) |cp| {
                if (cp) |cpoint| {
                    const p = cpoint.point.add(nmom);
                    // Get the line, `ab`, of the collision between `p` and `collision.face`.
                    var a: ?Vector = null;
                    var b: ?Vector = null;
                    var ang1: f32 = 360;
                    var ang2: f32 = 360;
                    for ([4]Vector{ col.face.p1, col.face.p2, col.face.p3, col.face.p4 }) |fp| {
                        const abs_fp = fp.add(col.face.owner.position);
                        const ang = abs_fp.subtract(cpoint.point).evalAngleWith(nmom);
                        if (ang < ang1) {
                            ang2 = ang1;
                            b = a;
                            ang1 = ang;
                            a = abs_fp;
                            continue;
                        }
                        if (ang < ang2) {
                            ang2 = ang;
                            b = abs_fp;
                            continue;
                        }
                    }

                    if (a == null or b == null) continue;

                    // Get the point c which is the insection of point p with the
                    // line `ab` while moving in the direction `-nmom`.
                    const c = getPointLineTrajectory(p, a.?, b.?, rigid1.velocity);
                    if (c == null) continue;

                    const mag = c.?.subtract(p).magnitude();
                    if (min_mag == null or mag < min_mag.?) min_mag = mag;
                }
            }
        }

        if (min_mag) |n| {
            obj1.position = pos1.add(rigid1.velocity.normalize().multiply(n));
        }
    }

    // Ensure there are no remaining collisions
    // dc.detectCollision();
    // if (self.jammingExist(0.5)) return self.resolve(false);
}

fn jammingExist(self: *JammingResolver, threshold: f32) bool {
    for (self._objects.items) |obj| {
        self._collisions.clearRetainingCapacity();
        self._collisionDetector.getCollisions(self._allocator, obj, &self._collisions) catch {
            std.log.err("JammingResolver.resolve: collisions couldn't be detected!", .{});
            return false;
        };
        for (self._collisions.items) |c| {
            inline for (c.cps) |cp| {
                if (cp) |cpoint| {
                    const cx = @abs(cpoint.mag.x);
                    const cy = @abs(cpoint.mag.y);
                    const mc = @min(cx, cy); // TODO: include c.z
                    if (mc > threshold) return true;
                }
            }
        }
    }
    return false;
}

/// Get the point on line `ab` which is the trajectory of
/// point p, on line `ab`, moving in direction `r`.
/// TODO: add the z dimention, into account, in this algorithm.
fn getPointLineTrajectory(
    pp: Vector, // point p
    pa: Vector, // point a
    pb: Vector, // point b
    dr: Vector, // direction r
) ?Vector {
    if (pa.isEql(pb)) return null;

    var res: Vector = .{ .z = pp.z };

    // NOTE: if the slop is null then res.x shall equal pp.x.
    const slop: ?f32 = if (dr.x > 0) dr.y / dr.x else null;

    // In case the line is horizontal use equations for this specific case. Otherwise,
    // we can generally and safely use other equations (the one for horizontal lines)
    if (pa.y == pb.y) {
        if (slop) |s| {
            const nume: f32 = ((pa.x - pb.x) * (pp.y - (s * pp.x))) - ((pb.y * pa.x) + (pb.x * pa.y));
            const deno: f32 = (pa.y - pb.y) - ((pa.x - pb.x) * s);
            res.x = nume / deno;
        } else {
            res.x = pp.x;
        }
        res.y = (((pa.y - pb.y) * res.x) - (pb.x * pa.y) + (pb.y * pa.x)) / (pa.x - pb.x);
    } else {
        if (slop) |s| {
            const nume: f32 = ((pa.y - pb.y) * (pp.y - (pp.x * s))) + (((pb.x * pa.y) - (pb.y * pa.x)) * s);
            const deno: f32 = (pa.y - pb.y) - ((pa.x - pb.x) * s);
            res.y = nume / deno;
        } else {
            res.y = pp.y;
        }
        res.x = ((pa.x - pb.x) * res.y) - (pb.y * pa.x) + (pb.x * pa.y) / (pa.y - pb.y);
    }

    return res;
}

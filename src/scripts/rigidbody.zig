//! Add this script to any object in order to bestow it with physical properties.

const std = @import("std");
const modules = @import("../modules/mod.zig");
const plugins = @import("../plugins/mod.zig");
const types = @import("../types/mod.zig");
const Mesh = @import("./mesh.zig");

const Rigidbody = @This();

mass: f32, // TODO: use it in the update method logic
gravity: bool = false,
static: bool = false,

_G: f32 = 0.005, // The Gravitational Constant
_vel: types.Vector = .{}, // Velocity
_acc: types.Vector = .{}, // Acceleration
_pfr: types.Vector = .{}, // Frictions of the position directions
_nfr: types.Vector = .{}, // Frictions of the negative directions
_collisions: std.ArrayList(types.Collision) = .empty,

_allocator: std.mem.Allocator,
_script_strategy: modules.ScriptStrategy,
_collisionDetector: ?*plugins.CollisionDetector = null,

pub fn init(data: struct {
    allocator: std.mem.Allocator,
    mass: f32 = 5,
    gravity: bool = false,
    static: bool = false,
}) !*Rigidbody {
    // Ensure required plugins are available
    const cd = modules.PluginManager.get(plugins.CollisionDetector, "CollisionDetector");
    if (cd == null) return error.CollisionDetectorRequired;

    // Initialize the script
    var rigidbody = try data.allocator.create(Rigidbody);
    rigidbody.mass = data.mass;
    rigidbody.gravity = data.gravity;
    rigidbody.static = data.static;
    rigidbody._allocator = data.allocator;
    rigidbody._script_strategy = .{
        .start = start,
        .update = update,
        .end = end,
    };
    rigidbody._collisionDetector = cd;
    rigidbody._collisions = .empty;
    rigidbody._vel = .{};
    rigidbody._acc = .{};
    rigidbody._G = 0.005;
    return rigidbody;
}

pub fn deinit(self: *Rigidbody) void {
    self._collisions.deinit(self._allocator);
    self._allocator.destroy(self);
}

pub fn toScript(self: *Rigidbody) modules.Script {
    return modules.Script{
        .name = "Rigidbody",
        .strategy = &self._script_strategy,
    };
}

fn start(s: *modules.Script, obj: *modules.Object) void {
    const self = @as(*Rigidbody, @constCast(
        @fieldParentPtr("_script_strategy", s.strategy),
    ));
    if (self.static) {
        self._pfr = .{ .x = 1.00, .y = 1.00, .z = 1.00 };
        self._nfr = .{ .x = 1.00, .y = 1.00, .z = 1.00 };
    } else {
        if (modules.PluginManager.get(plugins.JammingResolver, "JammingResolver")) |jr| {
            jr.addObject(obj) catch std.log.warn(
                "Rigidbody.start: couldn't add the object into the JammingResolver!",
                .{},
            );
        }
    }
}

fn update(s: *modules.Script, obj: *modules.Object) void {
    const self = @as(*Rigidbody, @constCast(
        @fieldParentPtr("_script_strategy", s.strategy),
    ));
    if (self.static) return;

    // Motion Decay
    self._vel.x -= if (self._vel.x > 0) self._vel.x * self._nfr.x else self._vel.x * self._pfr.x;
    self._vel.y -= if (self._vel.y > 0) self._vel.y * self._nfr.y else self._vel.y * self._pfr.y;
    self._vel.z -= if (self._vel.z > 0) self._vel.z * self._nfr.z else self._vel.z * self._pfr.z;

    self._acc.x -= if (self._acc.x > 0) self._acc.x * self._nfr.x else self._acc.x * self._pfr.x;
    self._acc.y -= if (self._acc.y > 0) self._acc.y * self._nfr.y else self._acc.y * self._pfr.y;
    self._acc.z -= if (self._acc.z > 0) self._acc.z * self._nfr.z else self._acc.z * self._pfr.z;

    // Motion Influence
    obj.position = obj.position.add(self._vel);
    _ = self.applyMomentum(self._acc);
    if (self.gravity) _ = self.applyForce(.{ .y = @max(0, self._G) });

    // Reset Frictions
    self._pfr = self._pfr.multiply(0);
    self._nfr = self._nfr.multiply(0);

    // Detect collision, reslove jamming, and calculate frictions
    self._collisions.clearRetainingCapacity();
    self._collisionDetector.?.getCollisions(obj, self._allocator, &self._collisions) catch unreachable;

    for (self._collisions.items) |collision| {
        const cobj = collision.face.owner;
        if (cobj.getScript(Rigidbody, "Rigidbody")) |rbody| {
            inline for (collision.cps) |cp| {
                if (cp) |cpoint| {
                    const cx = @abs(cpoint.mag.x);
                    const cy = @abs(cpoint.mag.y);
                    // const cz = @abs(cpoint.z); TODO: enable z axis as well for 3D
                    const mc = @min(cx, cy);
                    if (mc == cx) {
                        if (cpoint.mag.x > 0) self._pfr.x = @min(1.00, self._pfr.x + rbody._pfr.x) //
                        else self._nfr.x = @min(1.00, self._nfr.x + rbody._nfr.x);
                    } else if (mc == cy) {
                        if (cpoint.mag.y > 0) self._pfr.y = @min(1.00, self._pfr.y + rbody._pfr.y) //
                        else self._nfr.y = @min(1.00, self._nfr.y + rbody._nfr.y);
                    }
                }
            }
        }
    }
}

fn end(_: *modules.Script, obj: *modules.Object) void {
    if (modules.PluginManager.get(plugins.JammingResolver, "JammingResolver")) |jr| {
        jr.rmvObject(obj);
    }
}

/// Apply force to the object and get a reaction force.
/// NOTE: this mutates the inner state.
pub fn applyForce(self: *Rigidbody, f: types.Vector) types.Vector {
    if (self.static) return f.multiply(-1);
    const res = self._acc.subtract(f);
    self._acc = self._acc.add(f);
    return res;
}

/// Apply momentum to the object and get a reaction momentum.
/// NOTE: this mutates the inner state.
pub fn applyMomentum(self: *Rigidbody, f: types.Vector) types.Vector {
    if (self.static) return f.multiply(-1);
    self._vel = self._vel.add(f);
    return self._vel;
}

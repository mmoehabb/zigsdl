//! Add this script to any object in order to bestow it with physical properties.

const std = @import("std");
const modules = @import("../modules/mod.zig");
const plugins = @import("../plugins/mod.zig");
const types = @import("../types/mod.zig");
const Mesh = @import("./mesh.zig");

const Rigidbody = @This();

mass: f32, // TODO: use it in the update method logic
gravity: f32 = 0.00,
static: bool = false,

velocity: types.Vector = .{},
acceleration: types.Vector = .{},
_friction: types.Vector = .{},
_collisions: std.ArrayList(types.Collision) = .empty,
_impactors: std.ArrayList(*modules.Object) = .empty,

_allocator: std.mem.Allocator,
_script_strategy: modules.ScriptStrategy,
_collisionDetector: ?*plugins.CollisionDetector = null,

pub fn init(data: struct {
    allocator: std.mem.Allocator,
    mass: f32 = 5,
    gravity: f32 = 0.00,
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
    rigidbody._impactors = .empty;
    rigidbody.velocity = .{};
    rigidbody.acceleration = .{};
    return rigidbody;
}

pub fn deinit(self: *Rigidbody) void {
    self._collisions.deinit(self._allocator);
    self._impactors.deinit(self._allocator);
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
    if (!self.static) {
        if (modules.PluginManager.get(plugins.JammingResolver, "JammingResolver")) |jr| {
            jr.addObject(obj) catch std.log.warn(
                "Rigidbody.start: couldn't add the object into the JammingResolver!",
                .{},
            );
        }
    }
}

fn update(s: *modules.Script, obj: *modules.Object, dt: f32) void {
    const self = @as(*Rigidbody, @constCast(
        @fieldParentPtr("_script_strategy", s.strategy),
    ));
    if (self.static) return;

    // 1) Re-evaluate the friction vector based on the current collisions.
    self._friction = self._friction.multiply(0);
    self._collisions.clearRetainingCapacity();
    self._collisionDetector.?.getCollisions(self._allocator, obj, &self._collisions) catch unreachable;

    var vel_reactions = types.Vector{};
    var acc_reactions = types.Vector{};

    for (self._collisions.items) |collision| {
        var cobj = collision.face.owner;
        if (cobj == obj) cobj = collision.myface.owner;

        // skip this object if it's within the impactors list
        var found = false;
        for (self._impactors.items) |impactor| {
            if (impactor == cobj) found = true;
        }
        if (found) continue;

        if (cobj.getScript(Rigidbody, "Rigidbody")) |rbody| {
            std.debug.print("{s} -> {s}\n", .{ obj.name, cobj.name });
            const reaction = rbody.impact(obj);
            vel_reactions = vel_reactions.add(reaction.vel);
            acc_reactions = acc_reactions.add(reaction.acc);
        }
    }
    self._impactors.clearRetainingCapacity();

    // 2) Apply motion decay using the evaluated friction.
    _ = self.applyMomentum(vel_reactions);
    _ = self.applyForce(acc_reactions);

    // 3) Finally, move the object and update the rigidbody state.
    self.velocity = self.velocity.add(self.acceleration);
    obj.position = obj.position.add(self.velocity);

    self.acceleration.y = @max(self.acceleration.y, 9.8 * self.gravity * dt);
}

fn end(_: *modules.Script, obj: *modules.Object) void {
    if (modules.PluginManager.get(plugins.JammingResolver, "JammingResolver")) |jr| {
        jr.rmvObject(obj);
    }
}

/// Apply force to the object and get a reaction force.
/// NOTE: this mutates the inner state.
pub fn applyForce(self: *Rigidbody, f: types.Vector) types.Vector {
    const res = self.acceleration.subtract(f);
    if (!self.static) self.acceleration = self.acceleration.add(f);
    return res;
}

/// Apply momentum to the object and get a reaction momentum.
/// NOTE: this mutates the inner state.
pub fn applyMomentum(self: *Rigidbody, f: types.Vector) types.Vector {
    const res = self.velocity.subtract(f);
    if (!self.static) self.velocity = self.velocity.add(f);
    return res;
}

pub fn impact(self: *Rigidbody, obj: *modules.Object) struct {
    vel: types.Vector = .{},
    acc: types.Vector = .{},
} {
    if (obj.getScript(Rigidbody, "Rigidbody")) |rbody| {
        if (!self.static) self._impactors.append(self._allocator, obj) catch unreachable;
        if (self.velocity.isEql(rbody.velocity)) return .{};
        return .{
            .vel = self.applyMomentum(rbody.velocity),
            .acc = self.applyForce(rbody.acceleration),
        };
    }
    return .{};
}

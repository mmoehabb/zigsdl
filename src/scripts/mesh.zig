//! Bestow objects with physical properties by specifying its mesh
//! structure. Add this to objects in order to detect collisions.

const std = @import("std");

const plugins = @import("../plugins/mod.zig");
const modules = @import("../modules/mod.zig");
const types = @import("../types/mod.zig");

const Mesh = @This();

/// The points that aligns the structure of the object mesh.
/// NOTE: It's relative to the objects position.
faces: []types.Face,

_allocator: std.mem.Allocator,
_script_strategy: modules.ScriptStrategy,

pub fn init(allocator: std.mem.Allocator, faces: []types.Face) !*Mesh {
    var mesh = try allocator.create(Mesh);
    mesh.faces = try allocator.dupe(types.Face, faces);
    mesh._allocator = allocator;
    mesh._script_strategy = modules.ScriptStrategy{
        .start = start,
        .update = update,
        .end = end,
    };
    return mesh;
}

pub fn deinit(self: *Mesh) void {
    self._allocator.free(self.faces);
    self._allocator.destroy(self);
}

pub fn toScript(self: *Mesh) modules.Script {
    return modules.Script{
        .name = "Mesh",
        .strategy = &self._script_strategy,
    };
}

fn start(_: *modules.Script, obj: *modules.Object) void {
    modules.PluginManager.get(plugins.CollisionDetector, "CollisionDetector").?.addObject(obj) catch std.debug.print(
        "Mesh: couldn't add object into the physics engine!",
        .{},
    );
}

fn update(_: *modules.Script, _: *modules.Object, _: f32) void {}

fn end(_: *modules.Script, obj: *modules.Object) void {
    modules.PluginManager.get(plugins.CollisionDetector, "CollisionDetector").?.rmvObject(obj);
}

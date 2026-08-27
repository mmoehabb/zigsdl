//! A simple movement script.

const std = @import("std");
const modules = @import("../modules/mod.zig");
const plugins = @import("../plugins/mod.zig");
const types = @import("../types/mod.zig");

const Movement = @This();

velocity: f32 = 5,
smooth: bool = true,

_script_strategy: modules.ScriptStrategy = modules.ScriptStrategy{
    .start = start,
    .update = update,
    .end = end,
},

_last_pressed: types.event.Key = .Unknown,

_allocator: std.mem.Allocator,
_em: *plugins.EventManager,

pub fn init(allocator: std.mem.Allocator, velocity: f32, smooth: bool) !*Movement {
    const eventManager = modules.PluginManager.get(plugins.EventManager, "EventManager");
    if (eventManager) |em| {
        var script = try allocator.create(Movement);
        script.velocity = velocity;
        script.smooth = smooth;
        script._last_pressed = .Unknown;
        script._script_strategy = .{
            .start = start,
            .update = update,
            .end = end,
        };
        script._allocator = allocator;
        script._em = em;
        return script;
    }
    std.log.err("Movement.init: the EventManager plugin is required.", .{});
    return error.EventManagerRequired;
}

pub fn deinit(self: *Movement) void {
    self._allocator.destroy(self);
}

pub fn toScript(self: *Movement) modules.Script {
    return modules.Script{
        .name = "Movement",
        .strategy = &self._script_strategy,
    };
}

fn start(_: *modules.Script, _: *modules.Object) void {}

fn update(s: *modules.Script, o: *modules.Object, _: f32) void {
    const obj = o;
    const self = @as(*Movement, @constCast(
        @fieldParentPtr("_script_strategy", s.strategy),
    ));

    if (self.smooth) {
        if (self._em.isKeyDown(.W)) obj.position.y -= self.velocity;
        if (self._em.isKeyDown(.S)) obj.position.y += self.velocity;
        if (self._em.isKeyDown(.D)) obj.position.x += self.velocity;
        if (self._em.isKeyDown(.A)) obj.position.x -= self.velocity;
        return;
    }

    // Moving the object un-smoothely
    if (self._em.isKeyDown(.W) and self._last_pressed != .W) {
        obj.position.y -= self.velocity;
        self._last_pressed = .W;
    } else if (self._em.isKeyDown(.S) and self._last_pressed != .S) {
        obj.position.y += self.velocity;
        self._last_pressed = .S;
    } else if (self._em.isKeyDown(.D) and self._last_pressed != .D) {
        obj.position.x += self.velocity;
        self._last_pressed = .D;
    } else if (self._em.isKeyDown(.A) and self._last_pressed != .A) {
        obj.position.x -= self.velocity;
        self._last_pressed = .A;
    }

    // Reset _last_pressed on each key up
    if (self._em.isKeyUp(.W) and self._last_pressed == .W) {
        self._last_pressed = .Unknown;
    } else if (self._em.isKeyUp(.S) and self._last_pressed == .S) {
        self._last_pressed = .Unknown;
    } else if (self._em.isKeyUp(.D) and self._last_pressed == .D) {
        self._last_pressed = .Unknown;
    } else if (self._em.isKeyUp(.A) and self._last_pressed == .A) {
        self._last_pressed = .Unknown;
    }
}

fn end(_: *modules.Script, _: *modules.Object) void {}

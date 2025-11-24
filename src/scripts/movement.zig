//! A simple movement script.

const std = @import("std");
const modules = @import("../modules/mod.zig");
const types = @import("../types/mod.zig");
const AudioPlayer = @import("../scripts/mod.zig").AudioPlayer;

const Movement = @This();

velocity: f32 = 5,
smooth: bool = true,

_script_strategy: modules.ScriptStrategy = modules.ScriptStrategy{
    .start = start,
    .update = update,
    .end = end,
},

_last_pressed: types.event.Key = .Unknown,

pub fn toScript(self: *Movement) modules.Script {
    return modules.Script{
        .name = "Movement",
        .strategy = &self._script_strategy,
    };
}

fn start(_: *modules.Script, _: *modules.Object) void {}

fn update(s: *modules.Script, o: *modules.Object) void {
    const obj = o;
    const self = @as(*Movement, @constCast(
        @fieldParentPtr("_script_strategy", s.strategy),
    ));
    var em = o.*._scene.?.screen.?.getEventManager();

    if (self.smooth) {
        if (em.isKeyDown(.W)) obj.position.y -= self.velocity;
        if (em.isKeyDown(.S)) obj.position.y += self.velocity;
        if (em.isKeyDown(.D)) obj.position.x += self.velocity;
        if (em.isKeyDown(.A)) obj.position.x -= self.velocity;
        return;
    }

    // Moving the object un-smoothely
    if (em.isKeyDown(.W) and self._last_pressed != .W) {
        obj.position.y -= self.velocity;
        self._last_pressed = .W;
    } else if (em.isKeyDown(.S) and self._last_pressed != .S) {
        obj.position.y += self.velocity;
        self._last_pressed = .S;
    } else if (em.isKeyDown(.D) and self._last_pressed != .D) {
        obj.position.x += self.velocity;
        self._last_pressed = .D;
    } else if (em.isKeyDown(.A) and self._last_pressed != .A) {
        obj.position.x -= self.velocity;
        self._last_pressed = .A;
    }

    // Reset _last_pressed on each key up
    if (em.isKeyUp(.W) and self._last_pressed == .W) {
        self._last_pressed = .Unknown;
    } else if (em.isKeyUp(.S) and self._last_pressed == .S) {
        self._last_pressed = .Unknown;
    } else if (em.isKeyUp(.D) and self._last_pressed == .D) {
        self._last_pressed = .Unknown;
    } else if (em.isKeyUp(.A) and self._last_pressed == .A) {
        self._last_pressed = .Unknown;
    }
}

fn end(_: *modules.Script, _: *modules.Object) void {}

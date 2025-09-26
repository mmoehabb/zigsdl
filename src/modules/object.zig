const c = @cImport({
    @cInclude("SDL3/SDL.h");
});
const std = @import("std");

const Drawable = @import("./drawable.zig").Drawable;
const Script = @import("./script.zig").Script;
const Position = @import("../types/common.zig").Position;
const Rotation = @import("../types/common.zig").Rotation;

pub const Object = struct {
    position: Position,
    rotation: Rotation,
    drawable: *const Drawable,

    const scripts = std.ArrayList(Script).init(std.heap.page_allocator);

    pub fn deinit(_: *Object) !void {
        for (scripts.items) |script| {
            if (script.end) |func| func();
        }
        scripts.deinit();
    }

    pub fn start(_: *Object) !void {
        for (scripts.items) |script| {
            if (script.start) |func| func();
        }
    }

    pub fn update(self: *Object, renderer: *c.SDL_Renderer) !void {
        for (scripts.items) |script| {
            if (script.update) |func| func();
        }
        try self.drawable.draw(renderer, self.position, self.rotation);
    }

    pub fn addScript(self: *Object, script: Script) !void {
        script.setObject(self);
        try scripts.addOne(script);
    }
};

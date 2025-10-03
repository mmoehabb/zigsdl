const c = @cImport({
    @cInclude("SDL3/SDL.h");
});
const std = @import("std");

const Scene = @import("./scene.zig").Scene;
const Drawable = @import("./drawable.zig").Drawable;
const Script = @import("./script.zig").Script;
const Position = @import("../types/common.zig").Position;
const Rotation = @import("../types/common.zig").Rotation;

pub const Object = struct {
    position: Position,
    rotation: Rotation,
    drawable: *const Drawable,
    scene: ?*Scene,

    var scripts = std.ArrayList(Script).init(std.heap.page_allocator);

    pub fn deinit(self: *Object) !void {
        for (scripts.items) |script| {
            if (script.end) |func| func(self);
        }
        scripts.deinit();
    }

    pub fn start(self: *Object) !void {
        for (scripts.items) |script| {
            if (script.start) |func| func(self);
        }
    }

    pub fn update(self: *Object, renderer: *c.SDL_Renderer) !void {
        for (scripts.items) |script| {
            if (script.update) |func| func(self);
        }
        try self.drawable.draw(renderer, self.position, self.rotation);
    }

    pub fn addScript(_: *Object, script: Script) !void {
        try scripts.append(script);
    }

    pub fn setScene(self: *Object, scene: *Scene) void {
        self.scene = scene;
    }
};

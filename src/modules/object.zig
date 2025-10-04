const std = @import("std");
const sdl = @import("../sdl.zig");
const types = @import("../types/mod.zig");

const Scene = @import("./scene.zig").Scene;
const Drawable = @import("./drawable.zig").Drawable;
const Script = @import("./script.zig").Script;

pub const Object = struct {
    position: types.common.Position,
    rotation: types.common.Rotation,
    drawable: *const Drawable,
    scene: ?*Scene,

    var scripts = std.ArrayList(Script).empty;

    pub fn deinit(self: *Object) !void {
        for (scripts.items) |script| {
            script.end(self);
        }
        scripts.deinit(std.heap.page_allocator);
    }

    pub fn start(self: *Object) !void {
        for (scripts.items) |script| {
            script.start(self);
        }
    }

    pub fn update(self: *Object, renderer: *sdl.c.SDL_Renderer) !void {
        for (scripts.items) |script| {
            script.update(self);
        }
        try self.drawable.draw(renderer, self.position, self.rotation);
    }

    pub fn addScript(_: *Object, script: Script) !void {
        try scripts.append(std.heap.page_allocator, script);
    }

    pub fn setScene(self: *Object, scene: *Scene) void {
        self.scene = scene;
    }
};

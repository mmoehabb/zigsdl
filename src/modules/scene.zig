const c = @cImport({
    @cInclude("SDL3/SDL.h");
});
const std = @import("std");
const ArrayList = @import("std").ArrayList;

const Object = @import("./object.zig").Object;

pub const Scene = struct {
    var objects = ArrayList(*Object).init(std.heap.page_allocator);

    pub fn new() Scene {
        return Scene{};
    }

    pub fn deinit(_: *Scene) void {
        for (objects.items) |obj| try obj.deinit();
        objects.deinit();
    }

    pub fn start(_: *Scene) !void {
        for (objects.items) |obj| try obj.start();
    }

    pub fn update(_: *Scene, renderer: *c.SDL_Renderer) !void {
        for (objects.items) |obj| try obj.update(renderer);
    }

    pub fn addObject(_: *Scene, obj: *Object) !void {
        try objects.append(obj);
    }
};

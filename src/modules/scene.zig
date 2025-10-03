const c = @cImport({
    @cInclude("SDL3/SDL.h");
});
const std = @import("std");

const Screen = @import("./screen.zig").Screen;
const Object = @import("./object.zig").Object;

pub const Scene = struct {
    screen: ?*Screen,
    var objects = std.ArrayList(*Object).init(std.heap.page_allocator);

    pub fn new() Scene {
        return Scene{ .screen = undefined };
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

    pub fn addObject(self: *Scene, obj: *Object) !void {
        obj.scene = self;
        try objects.append(obj);
    }

    pub fn setScreen(self: *Scene, screen: *Screen) void {
        self.screen = screen;
    }
};

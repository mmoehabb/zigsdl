const std = @import("std");
const sdl = @import("../sdl.zig");

const Screen = @import("./screen.zig").Screen;
const Object = @import("./object.zig").Object;

pub const Scene = struct {
    screen: ?*Screen,
    var objects = std.ArrayList(*Object).empty;

    pub fn new() Scene {
        return Scene{ .screen = undefined };
    }

    pub fn deinit(_: *Scene) void {
        for (objects.items) |obj| try obj.deinit();
        objects.deinit(std.heap.page_allocator);
    }

    pub fn start(_: *Scene) !void {
        for (objects.items) |obj| try obj.start();
    }

    pub fn update(_: *Scene, renderer: *sdl.c.SDL_Renderer) !void {
        for (objects.items) |obj| try obj.update(renderer);
    }

    pub fn addObject(self: *Scene, obj: *Object) !void {
        obj.scene = self;
        try objects.append(std.heap.page_allocator, obj);
    }

    pub fn setScreen(self: *Scene, screen: *Screen) void {
        self.screen = screen;
    }
};

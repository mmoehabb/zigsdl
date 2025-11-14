const std = @import("std");
const sdl = @import("../sdl.zig");

const Screen = @import("./screen.zig").Screen;
const Object = @import("./object.zig").Object;

pub const Scene = struct {
    screen: ?*Screen,
    _objects: std.ArrayList(*Object) = std.ArrayList(*Object).empty,

    pub fn new() Scene {
        return Scene{ .screen = undefined };
    }

    pub fn deinit(self: *Scene) !void {
        for (self._objects.items) |obj| try obj.deinit();
        self._objects.deinit(std.heap.page_allocator);
    }

    pub fn start(self: *Scene) !void {
        for (self._objects.items) |obj| try obj.start();
    }

    pub fn update(self: *Scene, renderer: *sdl.c.SDL_Renderer) !void {
        for (self._objects.items) |obj| try obj.update(renderer);
    }

    pub fn addObject(self: *Scene, obj: *Object) !void {
        obj.setScene(self);
        try self._objects.append(std.heap.page_allocator, obj);
    }

    pub fn setScreen(self: *Scene, screen: *Screen) void {
        self.screen = screen;
    }
};

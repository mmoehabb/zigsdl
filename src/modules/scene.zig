const c = @cImport({
    @cInclude("SDL2/SDL.h");
});
const std = @import("std");
const ArrayList = @import("std").ArrayList;

const Object = @import("./object.zig").Object;

pub const Scene = struct {
    _allocator: std.mem.Allocator,
    _objects: ?*ArrayList(Object),

    pub fn init(self: *Scene) void {
        const gpa = std.heap.GeneralPurposeAllocator(.{}){};
        const allocator = gpa.allocator();
        self._objects = ArrayList(Object).init(allocator);
    }

    pub fn deinit(self: *Scene) void {
        for (self._objects.?.items) |obj| obj.deinit();
        self._objects.?.deinit();
    }

    pub fn start(self: *Scene) !void {
        for (self._objects.?.items) |obj| obj.start();
    }

    pub fn update(self: *Scene, renderer: *c.SDL_Renderer) !void {
        for (self._objects.?.items) |obj| try obj.update(renderer);
    }

    pub fn addObject(self: *Scene, obj: Object) !void {
        try self._objects.?.addOne(obj.init());
    }
};

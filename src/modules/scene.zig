const c = @cImport({
    @cInclude("SDL2/SDL.h");
});
const allocator = @import("std").mem.Allocator;
const ArrayList = @import("std").ArrayList;

const Object = @import("./object.zig").Object;

pub const Scene = struct {
    objects: ?*ArrayList(Object),

    pub fn init(self: *Scene) void {
        self.objects = ArrayList(Object).init(allocator);
    }

    pub fn start(self: *Scene) !void {
        for (self.objects.?.items) |obj| obj.start();
    }

    pub fn update(self: *Scene, renderer: *c.SDL_Renderer) !void {
        for (self.objects.?.items) |obj| try obj.update(renderer);
    }

    pub fn deinit(self: *Scene) void {
        for (self.objects.?.items) |obj| obj.deinit();
        self.objects.?.deinit();
    }

    pub fn addObject(self: *Scene, obj: Object) !void {
        try self.objects.?.addOne(obj.init());
    }
};

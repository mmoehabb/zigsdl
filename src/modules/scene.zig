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

    pub fn getObjectByName(self: *Scene, name: []const u8) ?*Object {
        for (self._objects.items) |obj| {
            if (std.mem.eql(u8, obj.name, name)) return obj;
        }

        for (self._objects.items) |obj| {
            const found = obj.getChildByName(name);
            if (found) |c| return c;
        }

        return null;
    }

    pub fn getObjectsByTag(self: *Scene, tag: []const u8, comptime max: u8) []?*Object {
        var res: [max]?*Object = .{null} ** max;

        var i: u8 = 0;
        for (self._objects.items) |o1| {
            if (i >= max) break;
            if (std.mem.eql(u8, o1.tag, tag)) res[i] = o1;
            i = i + 1;

            const inner_childs = o1.getChildsByTag(tag, max);
            for (inner_childs) |o2| {
                if (i >= max) break;
                if (o2) |_| {} else break;
                if (std.mem.eql(u8, o2.?.tag, tag)) res[i] = o2;
                i = i + 1;
            }
        }

        return res[0..i];
    }
};

//! A scene can be considered as a collection of [objects](#root.modules.object).
//! Scenes can be attached to only one screen. This can be done by
//! invoking the [setScreen](#root.modules.scene.setScreen) method.

const std = @import("std");
const sdl = @import("../sdl.zig");

const Screen = @import("./screen.zig");
const Object = @import("./object.zig");

const Scene = @This();

screen: ?*Screen,

_allocator: std.mem.Allocator,
_objects: std.ArrayList(*Object) = std.ArrayList(*Object).empty,

pub fn init(allocator: std.mem.Allocator) Scene {
    return Scene{
        .screen = undefined,
        ._allocator = allocator,
    };
}

pub fn deinit(self: *Scene) void {
    self._objects.deinit(self._allocator);
}

/// This ought to be invoked by the [screen](#root.modules.screen).
pub fn start(self: *Scene) !void {
    for (self._objects.items) |obj| try obj.start();
}

/// This ought to be invoked by the [screen](#root.modules.screen).
pub fn update(self: *Scene, renderer: *sdl.c.SDL_Renderer) !void {
    for (self._objects.items) |obj| try obj.update(renderer);
}

pub fn setScreen(self: *Scene, screen: *Screen) void {
    self.screen = screen;
}

/// Note: this also invokes [object.setScene](#root.modules.object.setScene) method.
pub fn addObject(self: *Scene, obj: *Object) !void {
    obj.setScene(self);
    try self._objects.append(self._allocator, obj);
}

/// Deep search the whole objects tree for an object with the specific passed name.
/// Note: it returns only the first one it founds.
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

/// Deep seach the whole objects tree and return a slice of the ones that have the passed tag.
///
/// :param tag: the object tag to be searched for.
/// :param max: the maximum number of objects to search for.
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

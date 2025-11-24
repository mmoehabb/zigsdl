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

/// Deep seach the whole objects tree and return an array of the ones that have the passed tag.
///
/// :param tag: the object tag to be searched for.
/// :param max: the maximum number of objects to search for.
pub fn getObjectsByTag(self: *Scene, tag: []const u8, comptime max: u8) struct {
    arr: [max]?*Object,
    size: u8,
} {
    var res: [max]?*Object = .{null} ** max;

    var i: u8 = 0;
    for (self._objects.items) |o1| {
        if (i >= max) break;
        if (std.mem.eql(u8, o1.tag, tag)) {
            res[i] = o1;
            i = i + 1;
        }

        const inner_childs = o1.getChildsByTag(tag, max);
        for (inner_childs.arr[0..inner_childs.size]) |o2| {
            if (i >= max) break;
            if (o2) |o| {
                if (std.mem.eql(u8, o.tag, tag)) {
                    res[i] = o2;
                    i = i + 1;
                }
            }
        }
    }

    return .{
        .arr = res,
        .size = i,
    };
}

test "Retrieve a certain object from the scene by its name" {
    const allocator = std.testing.allocator;
    const expect = std.testing.expect;

    var obj1 = Object.init(allocator, .{ .name = "Parent" });
    defer obj1.deinit();

    var obj2 = Object.init(allocator, .{ .name = "Child 1" });
    defer obj2.deinit();

    var obj3 = Object.init(allocator, .{ .name = "Child 2" });
    defer obj3.deinit();

    try obj1.addChild(&obj2);
    try obj1.addChild(&obj3);

    var scene = Scene.init(allocator);
    defer scene.deinit();
    try scene.addObject(&obj1);

    try expect(scene.getObjectByName("Child 2").? == &obj3);
}

test "Retrieve a slice of objects from the scene by their tag" {
    const allocator = std.testing.allocator;
    const expect = std.testing.expect;

    var obj1 = Object.init(allocator, .{});
    defer obj1.deinit();

    var obj2 = Object.init(allocator, .{
        .name = "First Wall",
        .tag = "wall",
    });
    defer obj2.deinit();

    var obj3 = Object.init(allocator, .{});
    defer obj3.deinit();

    var obj4 = Object.init(allocator, .{
        .name = "Second Wall",
        .tag = "wall",
    });
    defer obj4.deinit();

    try obj1.addChild(&obj2);
    try obj1.addChild(&obj3);
    try obj3.addChild(&obj4);

    var scene = Scene.init(allocator);
    defer scene.deinit();
    try scene.addObject(&obj1);

    const walls = scene.getObjectsByTag("wall", 5);
    try expect(walls.size == 2);
    try expect(walls.arr[0] == &obj2);
    try expect(walls.arr[1] == &obj4);
}

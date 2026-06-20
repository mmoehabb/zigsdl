//! A scene can be considered as a collection of [objects](#root.modules.object).
//! Scenes can be attached to only one screen. This can be done by
//! invoking the [setScreen](#root.modules.scene.setScreen) method.

const std = @import("std");
const sdl = @import("../sdl.zig");

const Screen = @import("./screen.zig");
const Object = @import("./object.zig");
const types = @import("../types/mod.zig");

const Scene = @This();

screen: ?*Screen,
origin: types.Position = types.Position{},
scale: f32 = 1.00,

/// The scene [lifecycle](#root.types.lifecycle).
lifecycle: types.LifeCycle = types.LifeCycle{},

_allocator: std.mem.Allocator,
_objects: std.ArrayList(*Object) = std.ArrayList(*Object).empty,
_objectNameMemo: std.StringHashMap(?*Object),
_objectsTagMemo: std.StringHashMap([]?*Object),

pub fn init(allocator: std.mem.Allocator) Scene {
    return Scene{
        .screen = undefined,
        ._allocator = allocator,
        ._objectNameMemo = std.StringHashMap(?*Object).init(allocator),
        ._objectsTagMemo = std.StringHashMap([]?*Object).init(allocator),
    };
}

pub fn deinit(self: *Scene) void {
    if (self.lifecycle.preClose) |func| func(self);
    self._objects.deinit(self._allocator);
    self._objectNameMemo.deinit();
    self._objectsTagMemo.deinit();
    if (self.lifecycle.postClose) |func| func(self);
}

/// This ought to be invoked by the [screen](#root.modules.screen).
pub fn start(self: *Scene) !void {
    if (self.lifecycle.preOpen) |func| func(self);
    for (self._objects.items) |obj| try obj.start();
    if (self.lifecycle.postOpen) |func| func(self);
}

/// This ought to be invoked by the [screen](#root.modules.screen).
pub fn update(self: *Scene, renderer: *sdl.c.SDL_Renderer) !void {
    if (self.lifecycle.preUpdate) |func| func(self);
    for (self._objects.items) |obj| try obj.update(renderer);
    if (self.lifecycle.postUpdate) |func| func(self);
}

pub fn setScreen(self: *Scene, screen: *Screen) void {
    self.screen = screen;
}

/// Move the scene (as camera) by _p.[dimension]_ units.
///
/// example:
/// ```zig
/// obj1.move(.{ x=20 });
/// ```
/// This moves _obj1_ by 20 units to the right.
/// NOTICE: it doesn't move **to** position _p_.
pub fn move(self: *Scene, p: types.Position) void {
    self.origin = self.origin.add(p);
}

/// Note: this also invokes [object.setScene](#root.modules.object.setScene) method.
pub fn addObject(self: *Scene, obj: *Object) !void {
    defer self.resetMemo();
    obj.setScene(self);
    // Objects should be ordered descendly; ensure to preserve this ordering.
    var i: usize = 0;
    for (self._objects.items, 0..) |item, j| {
        i = j;
        if (item.position.z <= obj.position.z) break;
    }
    try self._objects.insert(self._allocator, i, obj);
}

pub fn rmvObject(self: *Scene, obj: *Object) void {
    defer self.resetMemo();
    var i: ?usize = null;
    for (self._objects.items, 0..) |item, j| {
        if (item == obj) i = j;
    }
    if (i) |n| _ = self._objects.orderedRemove(n);
}

/// Deep search the whole objects tree for an object with the specific passed name.
/// Note: it returns only the first one it finds.
pub fn getObjectByName(self: *Scene, name: []const u8) !?*Object {
    if (self._objectNameMemo.get(name)) |found| return found;

    for (self._objects.items) |obj| {
        try self._objectNameMemo.put(obj.name, obj);
        if (std.mem.eql(u8, obj.name, name)) return obj;
    }

    for (self._objects.items) |obj| {
        // NOTE: getChildByName updates the memo state as well.
        const found = obj.getChildByName(name);
        if (found) |c| {
            try self._objectNameMemo.put(name, c);
            return c;
        }
    }

    try self._objectNameMemo.put(name, null);
    return null;
}

/// Deep search the whole objects tree and return an array of the ones that have the passed tag.
///
/// :param `tag`: the object tag to be searched for.
/// :param `max`: the maximum number of objects to search for.
pub fn getObjectsByTag(self: *Scene, tag: []const u8, comptime max: u8) struct {
    arr: [max]?*Object,
    size: usize,
} {
    // Craft the memo key
    var keyBuf: [128]u8 = .{0} ** 128;
    const key = std.fmt.bufPrint(&keyBuf, "{s}_{d}", .{ tag, max }) catch "NULL";

    // Get the memoized value if any exists
    if (self._objectsTagMemo.get(key)) |found| {
        var arr: [max]?*Object = .{null} ** max;
        @memcpy(arr[0..found.len], found);
        return .{
            .arr = arr,
            .size = found.len,
        };
    }

    var arr: [max]?*Object = .{null} ** max;
    defer self._objectsTagMemo.put(key, arr[0..]) catch {};

    var i: u8 = 0;
    for (self._objects.items) |o1| {
        if (i >= max) break;
        if (std.mem.eql(u8, o1.tag, tag)) {
            arr[i] = o1;
            i = i + 1;
        }

        const inner_childs = o1.getChildsByTag(tag, max);
        for (inner_childs.arr[0..inner_childs.size]) |o2| {
            if (i >= max) break;
            if (o2) |o| {
                if (std.mem.eql(u8, o.tag, tag)) {
                    arr[i] = o2;
                    i = i + 1;
                }
            }
        }
    }

    return .{
        .arr = arr,
        .size = i,
    };
}

pub fn resetMemo(self: *Scene) void {
    // TODO: This should be improved by clearing only a subset of the memoized data
    self._objectNameMemo.clearAndFree();
    self._objectsTagMemo.clearAndFree();
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

    const found = try scene.getObjectByName("Child 2");
    try expect(found != null);
    try expect(found.? == &obj3);
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

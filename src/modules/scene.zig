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
_objectsTagMemo: std.StringHashMap(std.ArrayList(*Object)),

pub fn init(allocator: std.mem.Allocator) Scene {
    return Scene{
        .screen = undefined,
        ._allocator = allocator,
        ._objectNameMemo = std.StringHashMap(?*Object).init(allocator),
        ._objectsTagMemo = std.StringHashMap(std.ArrayList(*Object)).init(allocator),
    };
}

pub fn deinit(self: *Scene) void {
    if (self.lifecycle.preClose) |func| func(self);

    self._objects.deinit(self._allocator);

    self._objectNameMemo.deinit();

    var vIter = self._objectsTagMemo.valueIterator();
    while (vIter.next()) |value| value.deinit(self._allocator);
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

/// Deep search the whole objects tree and return a slice of the ones with the passed tag.
pub fn getObjectsByTag(self: *Scene, tag: []const u8) ![]*Object {
    // Get the memoized value if any exists
    if (self._objectsTagMemo.get(tag)) |found| return found.items;

    var arr = try self._objectsTagMemo.getOrPutValue(tag, .empty);

    for (self._objects.items) |o1| {
        if (std.mem.eql(u8, o1.tag, tag)) {
            try arr.value_ptr.append(self._allocator, o1);
        }
        try o1.getChildsByTag(tag, arr.value_ptr);
    }

    return arr.value_ptr.items;
}

pub fn resetMemo(self: *Scene) void {
    // TODO: This should be improved by clearing only a subset of the memoized data
    self._objectNameMemo.clearAndFree();
    var vIter = self._objectsTagMemo.valueIterator();
    while (vIter.next()) |value| value.deinit(self._allocator);
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

    const walls = try scene.getObjectsByTag("wall");
    try expect(walls.len == 2);
    try expect(walls[0] == &obj2);
    try expect(walls[1] == &obj4);
}

test "Retrieve objects, more efficiently, with memoization" {
    const allocator = std.testing.allocator;
    const expect = std.testing.expect;

    var obj1 = Object.init(allocator, .{ .name = "Parent" });
    defer obj1.deinit();

    var obj2 = Object.init(allocator, .{ .name = "Child 1" });
    defer obj2.deinit();

    var obj3 = Object.init(allocator, .{ .name = "Child 1.1", .tag = "wing" });
    defer obj3.deinit();

    var obj4 = Object.init(allocator, .{ .name = "Child 1.2", .tag = "wing" });
    defer obj4.deinit();

    try obj1.addChild(&obj2);
    try obj2.addChild(&obj3);
    try obj2.addChild(&obj4);

    var scene = Scene.init(allocator);
    defer scene.deinit();
    try scene.addObject(&obj1);

    const found = try scene.getObjectByName("Child 1.1");
    try expect(found != null);
    try expect(found.? == &obj3);

    const wings = try scene.getObjectsByTag("wing");
    try expect(wings.len == 2);
    try expect(wings[0] == &obj3);
    try expect(wings[1] == &obj4);

    // Test the scene memo state
    try expect(scene._objectNameMemo.count() == 2);
    if (scene._objectNameMemo.getEntry("Child 1")) |e| {
        try expect(e.value_ptr.* == &obj2);
    }

    try expect(scene._objectsTagMemo.count() == 1);
    if (scene._objectsTagMemo.getEntry("wing")) |e| {
        const arr = e.value_ptr.items;
        try expect(arr.len == 2);
        try expect(arr[0] == &obj3);
        try expect(arr[1] == &obj4);
    }
}

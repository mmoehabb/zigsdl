//! This is the main component; without it drawables and scripts have no use,
//! and screens and scenes will be empty.
//!
//! An Object can be considered as a collection of scripts, a collection of objects,
//! a container of a drawable, or all the three together.

const std = @import("std");
const sdl = @import("../sdl.zig");
const types = @import("../types/mod.zig");

const Scene = @import("./scene.zig");
const Script = @import("./script.zig").Script;
const Drawable = @import("./drawable.zig").Drawable;

const Object = @This();

/// The position of the object relative to its parent.
position: types.Position,

/// The rotation of the object relative to its parent.
rotation: types.Rotation,

/// Unique name for the object, by which it can be retrieved from the parent.
name: []const u8,

/// The object tag. So that different kinds of objects can be classified.
/// For example: wall, static, ground, player, etc.
tag: []const u8,

/// A drawable, associated to a [concrete drawable](#root.drawables), that will get renderer.
drawable: ?*Drawable,

/// The object [lifecycle](#root.types.lifecycle).
lifecycle: types.LifeCycle = types.LifeCycle{},

_allocator: std.mem.Allocator,
_scene: ?*Scene = null,
_parent: ?*Object = null,
_scripts: std.ArrayList(*Script) = std.ArrayList(*Script).empty,
_children: std.ArrayList(*Object) = std.ArrayList(*Object).empty,
_active: bool,

pub fn init(
    allocator: std.mem.Allocator,
    params: struct {
        position: types.Position = types.Position{},
        rotation: types.Rotation = types.Rotation{},
        name: []const u8 = "unnamed",
        tag: []const u8 = "untagged",
        active: bool = true,
        drawable: ?*Drawable = null,
    },
) Object {
    return Object{
        .position = params.position,
        .rotation = params.rotation,
        .name = params.name,
        .tag = params.tag,
        .drawable = params.drawable,
        ._active = params.active,
        ._allocator = allocator,
    };
}

pub fn deinit(self: *Object) void {
    if (self.lifecycle.preClose) |func| func(self);

    if (self.drawable) |d| d.destroy();

    for (self._scripts.items) |script| script.end(self);
    self._scripts.deinit(self._allocator);

    self._children.deinit(self._allocator);

    if (self.lifecycle.postClose) |func| func(self);
}

/// This method shall only be invoked via the scene.
pub fn start(self: *Object) !void {
    if (!self._active) return;
    if (self.lifecycle.preOpen) |func| func(self);

    for (self._scripts.items) |script| script.start(self);
    for (self._children.items) |child| try child.start();

    if (self.lifecycle.postOpen) |func| func(self);
}

/// This method shall only be invoked via the scene.
pub fn update(self: *Object, renderer: *sdl.c.SDL_Renderer) !void {
    if (!self._active) return;
    if (self.lifecycle.preUpdate) |func| func(self);
    for (self._scripts.items) |script| script.update(self);

    const pos = if (self._parent) |p| self.position.add(p.position) else self.position;
    const rot = if (self._parent) |p| self.rotation.add(p.rotation) else self.rotation;

    if (self.drawable) |d| try d.draw(renderer, pos, rot);
    for (self._children.items) |child| try child.update(renderer);
    if (self.lifecycle.postUpdate) |func| func(self);
}

/// Note: Only activated objects are rendered in the scene, and their scripts are invoked.
pub fn activate(self: *Object) void {
    self._active = true;
    self.start();
}

/// Note: Only activated objects are rendered in the scene, and their scripts are invoked.
pub fn deactivate(self: *Object) void {
    self._active = false;
    for (self._scripts.items) |script| script.end(self);
}

pub fn setDrawable(self: *Object, drawable: *Drawable) void {
    if (self.drawable) |d| d.destroy();
    self.drawable = drawable;
}

pub fn getAbsPosition(self: *Object) types.Position {
    const parentPos = if (self._parent) |obj| obj.position else types.Position{};
    return self.position.add(parentPos);
}

pub fn setAbsPosition(self: *Object, pos: types.Position) void {
    const parentPos = if (self._parent) |obj| obj.position else types.Position{};
    self.position = pos.subtract(parentPos);
}

pub fn getAbsRotation(self: *Object) types.Rotation {
    const parentRot = if (self._parent) |obj| obj.rotation else types.Rotation{};
    return self.rotation.add(parentRot);
}

pub fn setAbsRotation(self: *Object, rot: types.Rotation) void {
    const parentRot = if (self._parent) |obj| obj.rotation else types.Rotation{};
    self.rotation = rot.subtract(parentRot);
}

pub fn addScript(self: *Object, script: *Script) !void {
    try self._scripts.append(self._allocator, script);
}

/// By convention, the name of any script equals exactly the name of the type.
/// See [root.modules.script.name](#root.modules.script.name).
pub fn getScript(self: *Object, P: type, name: []const u8) ?*P {
    for (self._scripts.items) |script| {
        if (std.mem.eql(u8, script.name, name)) {
            return @as(
                *P,
                @constCast(@fieldParentPtr(
                    "_script_strategy",
                    script.strategy,
                )),
            );
        }
    }
    return null;
}

pub fn setScene(self: *Object, scene: *Scene) void {
    self._scene = scene;
    for (self._children.items) |child| child.setScene(scene);
}

pub fn getChildByIndex(self: *Object, index: usize) *Object {
    return self._children.items[index];
}

/// Note: this also removes the child from the parent.
pub fn detach(self: *Object) void {
    const oldparent = self._parent;
    self._parent = null;
    if (oldparent) |p| p.rmvChild(self);
}

test "should detach the object from its parent; from both ways" {
    const allocator = std.testing.allocator;
    const expect = std.testing.expect;

    var parent = Object.init(allocator, .{});
    defer parent.deinit();

    var child = Object.init(allocator, .{ .name = "child" });
    defer child.deinit();

    try parent.addChild(&child);
    try expect(child._parent == &parent);
    try expect(parent.getChildByName("child") == &child);

    child.detach();
    try expect(child._parent == null);
    try expect(parent.getChildByName("child") == null);
}

/// Note: this also attaches the parent to the child, after detaching
/// the child from the old parent.
pub fn addChild(self: *Object, child: *Object) !void {
    try self._children.append(self._allocator, child);
    if (child._parent) |_| child.detach();
    child._parent = self;
    if (self._scene) |s| child.setScene(s);
}

test "should detach the child from its parent before adding it to the new one" {
    const allocator = std.testing.allocator;
    const expect = std.testing.expect;

    var oldparent = Object.init(allocator, .{});
    defer oldparent.deinit();

    var child = Object.init(allocator, .{ .name = "child" });
    defer child.deinit();

    try oldparent.addChild(&child);
    try expect(child._parent == &oldparent);
    try expect(oldparent.getChildByName("child") == &child);

    var newparent = Object.init(allocator, .{});
    defer newparent.deinit();

    try newparent.addChild(&child);
    try expect(child._parent == &newparent);
    try expect(newparent.getChildByName("child") == &child);
    try expect(oldparent.getChildByName("child") == null);
}

pub fn rmvChild(self: *Object, child: *Object) void {
    var index: isize = -1;
    for (self._children.items, 0..) |obj, i| {
        if (obj == child) {
            index = @intCast(i);
            break;
        }
    }
    if (index >= 0) {
        const c = self._children.orderedRemove(@intCast(index));
        c.detach();
    }
}

test "should detach the child from its parent after being removed" {
    const allocator = std.testing.allocator;
    const expect = std.testing.expect;

    var parent = Object.init(allocator, .{});
    defer parent.deinit();

    var child = Object.init(allocator, .{ .name = "child" });
    defer child.deinit();

    try parent.addChild(&child);
    try expect(child._parent == &parent);
    try expect(parent.getChildByName("child") == &child);

    parent.rmvChild(&child);
    try expect(child._parent == null);
    try expect(parent.getChildByName("child") == null);
}

/// Deep search the whole children tree for an object with the specific passed name.
/// Note: it returns only the first one it founds.
pub fn getChildByName(self: *Object, name: []const u8) ?*Object {
    for (self._children.items) |child| {
        if (std.mem.eql(u8, child.name, name)) return child;
    }

    for (self._children.items) |child| {
        const found = child.getChildByName(name);
        if (found) |c| return c;
    }

    return null;
}

/// Deep seach the whole children tree and return an array of the ones that have the passed tag.
///
/// :param tag: the object tag to be searched for.
/// :param max: the maximum number of objects to search for.
pub fn getChildsByTag(self: *Object, tag: []const u8, comptime max: u8) struct {
    arr: [max]?*Object,
    size: u8,
} {
    var res: [max]?*Object = .{null} ** max;

    var i: u8 = 0;
    for (self._children.items) |c1| {
        if (i >= max) break;
        if (std.mem.eql(u8, c1.tag, tag)) {
            res[i] = c1;
            i = i + 1;
        }

        const inner_childs = c1.getChildsByTag(tag, max);
        for (inner_childs.arr[0..inner_childs.size]) |c2| {
            if (i >= max) break;
            if (c2) |c| {
                if (std.mem.eql(u8, c.tag, tag)) {
                    res[i] = c2;
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

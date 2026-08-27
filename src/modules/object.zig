//! This is the main component; without it drawables and scripts have no use,
//! and screens and scenes will be empty.
//!
//! An Object can be considered as a collection of scripts, a collection of objects,
//! a container of a drawable, or all the three together.

const std = @import("std");
const sdl = @import("sdl");
const types = @import("../types/mod.zig");

const Scene = @import("./scene.zig");
const Script = @import("./script.zig").Script;
const Drawable = @import("./drawable.zig").Drawable;

const Object = @This();

/// The position of the object relative to its parent.
position: types.Vector,

/// The rotation of the object relative to its parent.
rotation: types.Vector,

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
_scripts: std.ArrayList(Script) = .empty,
_scripts_memo: std.StringHashMap(*Script),
_children: std.ArrayList(*Object) = .empty,
_active: bool,

pub fn init(
    allocator: std.mem.Allocator,
    props: struct {
        position: types.Vector = .{},
        rotation: types.Vector = .{},
        name: []const u8 = "unnamed",
        tag: []const u8 = "untagged",
        active: bool = true,
        drawable: ?*Drawable = null,
    },
) Object {
    return Object{
        .position = props.position,
        .rotation = props.rotation,
        .name = props.name,
        .tag = props.tag,
        .drawable = props.drawable,
        ._active = props.active,
        ._allocator = allocator,
        ._scripts_memo = std.StringHashMap(*Script).init(allocator),
    };
}

pub fn deinit(self: *Object) void {
    if (self.lifecycle.preClose) |func| func(self);

    self._active = false;
    if (self.drawable) |d| d.destroy();

    self._scripts_memo.deinit();
    for (self._scripts.items) |*script| script.end(self);
    self._scripts.deinit(self._allocator);

    self._children.deinit(self._allocator);

    if (self.lifecycle.postClose) |func| func(self);
}

/// This method shall only be invoked via the scene.
pub fn start(self: *Object) !void {
    if (!self._active) return;
    if (self.lifecycle.preOpen) |func| func(self);

    for (self._scripts.items) |*script| script.start(self);
    for (self._children.items) |child| try child.start();

    if (self.lifecycle.postOpen) |func| func(self);
}

/// This method shall only be invoked via the scene.
pub fn update(self: *Object, dt: f32) !void {
    if (!self._active) return;
    if (self.lifecycle.preUpdate) |func| func(self);
    for (self._scripts.items) |*script| script.update(self, dt);
    for (self._children.items) |child| try child.update(dt);
    if (self.lifecycle.postUpdate) |func| func(self);
}

/// This method shall only be invoked via the scene.
pub fn draw(self: *Object, renderer: *sdl.SDL_Renderer) !void {
    if (self.drawable) |drawable| {
        drawable.dim.sf = if (self._parent) |parent| blk: {
            break :blk parent.drawable.?.dim.scale * parent.drawable.?.dim.sf;
        } else self._scene.?.scale;

        const abs_scale = drawable.dim.getAbsScale();

        const pos = if (self._parent) |p| blk: {
            break :blk self.position.add(p.position).multiply(abs_scale);
        } else self.position.add(self._scene.?.origin).multiply(abs_scale);

        const rot = if (self._parent) |p| blk: {
            break :blk self.rotation.add(p.rotation);
        } else self.rotation;

        try drawable.draw(renderer, pos, rot);
    }
    for (self._children.items) |child| try child.draw(renderer);
}

/// Note: Only activated objects are rendered in the scene, and their scripts are invoked.
pub fn activate(self: *Object) void {
    self._active = true;
    self.start();
}

/// Note: Only activated objects are rendered in the scene, and their scripts are invoked.
pub fn deactivate(self: *Object) void {
    self._active = false;
    for (self._scripts.items) |*script| script.end(self);
}

pub fn setDrawable(self: *Object, drawable: *Drawable) void {
    if (self.drawable) |d| d.destroy();
    self.drawable = drawable;
}

pub fn getAbsPosition(self: *Object) types.Vector {
    const parentPos = if (self._parent) |obj| obj.position else types.Vector{};
    return self.position.add(parentPos);
}

pub fn setAbsPosition(self: *Object, pos: types.Vector) void {
    const parentPos = if (self._parent) |obj| obj.position else types.Vector{};
    self.position = pos.subtract(parentPos);
}

pub fn getAbsRotation(self: *Object) types.Vector {
    const parentRot = if (self._parent) |obj| obj.rotation else types.Vector{};
    return self.rotation.add(parentRot);
}

pub fn setAbsRotation(self: *Object, rot: types.Vector) void {
    const parentRot = if (self._parent) |obj| obj.rotation else types.Vector{};
    self.rotation = rot.subtract(parentRot);
}

pub fn addScript(self: *Object, script: Script) !void {
    try self._scripts.append(self._allocator, script);
}

/// By convention, the name of any script should equal exactly the name of the type.
/// See [root.modules.script.name](#root.modules.script.name).
pub fn getScript(self: *Object, P: type, name: []const u8) ?*P {
    if (self._scripts_memo.get(name)) |found| {
        return @as(
            *P,
            @constCast(@fieldParentPtr(
                "_script_strategy",
                found.strategy,
            )),
        );
    }

    var found: ?*P = null;
    for (self._scripts.items) |*script| {
        if (std.mem.eql(u8, script.name, name)) {
            found = @as(
                *P,
                @constCast(@fieldParentPtr(
                    "_script_strategy",
                    script.strategy,
                )),
            );
            self._scripts_memo.put(name, script) catch {};
            break;
        }
    }
    return found;
}

pub fn setScene(self: *Object, scene: *Scene) void {
    if (self._scene) |s| s.rmvObject(self);
    self._scene = scene;
    for (self._children.items) |child| child.setScene(scene);
}

pub fn getChildByIndex(self: *Object, index: usize) *Object {
    return self._children.items[index];
}

/// Note: this also removes the child from the parent (it mutates the parent state).
pub fn detach(self: *Object) void {
    const oldparent = self._parent;
    self._parent = null;
    if (oldparent) |p| p.rmvChild(self);
}

/// This attaches the parent to the child, and vise versa, after
/// detaching the child from its old parent.
pub fn addChild(self: *Object, child: *Object) !void {
    defer if (self._scene) |s| s.resetMemo();
    // TODO: should keep the children array sorted by position.z
    try self._children.append(self._allocator, child);
    if (child._parent) |_| child.detach();
    child._parent = self;
    if (self._scene) |s| child.setScene(s);
}

pub fn rmvChild(self: *Object, child: *Object) void {
    defer if (self._scene) |s| s.resetMemo();
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

/// Deep search the whole children tree for an object with the specific passed name.
/// NOTE: It returns only the first one it finds.
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

/// Deep search the whole children tree and append the found
/// objects into the passed array.
pub fn getChildsByTag(self: *Object, tag: []const u8, arr: *std.ArrayList(*Object)) !void {
    for (self._children.items) |c1| {
        if (std.mem.eql(u8, c1.tag, tag)) {
            try arr.append(self._allocator, c1);
        }
        try c1.getChildsByTag(tag, arr);
    }
}

// ====================================
// =========== UNIT TESTS =============
// ====================================
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

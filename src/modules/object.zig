const std = @import("std");
const sdl = @import("../sdl.zig");
const types = @import("../types/mod.zig");

const Scene = @import("./scene.zig").Scene;
const Drawable = @import("./drawable.zig").Drawable;
const Script = @import("./script.zig").Script;

pub const Object = struct {
    position: types.common.Position,
    rotation: types.common.Rotation,

    name: []const u8,
    tag: []const u8,
    active: bool,
    drawable: ?*Drawable,
    scene: ?*Scene,
    parent: ?*Object,

    _scripts: std.ArrayList(*Script) = std.ArrayList(*Script).empty,
    _children: std.ArrayList(*Object) = std.ArrayList(*Object).empty,

    lifecycle: types.common.LifeCycle = types.common.LifeCycle{
        .preOpen = null,
        .postOpen = null,
        .preUpdate = null,
        .postUpdate = null,
        .preClose = null,
        .postClose = null,
    },

    pub fn new(props: struct {
        position: types.common.Position,
        rotation: types.common.Rotation,
        name: []const u8 = "unnamed",
        tag: []const u8 = "untagged",
        active: bool = true,
        drawable: ?*Drawable = null,
        scene: ?*Scene = null,
        parent: ?*Object = null,
    }) Object {
        return Object{
            .position = props.position,
            .rotation = props.rotation,
            .name = props.name,
            .tag = props.tag,
            .active = props.active,
            .drawable = props.drawable,
            .scene = props.scene,
            .parent = props.parent,
        };
    }

    pub fn start(self: *Object) !void {
        if (!self.active) return;
        if (self.lifecycle.preOpen) |func| func(self);

        for (self._scripts.items) |script| script.start(self);
        for (self._children.items) |child| try child.start();

        if (self.lifecycle.postOpen) |func| func(self);
    }

    pub fn update(self: *Object, renderer: *sdl.c.SDL_Renderer) !void {
        if (!self.active) return;
        if (self.lifecycle.preUpdate) |func| func(self);
        for (self._scripts.items) |script| script.update(self);

        const pos = if (self.parent) |p| self.position.add(p.position) else self.position;
        const rot = if (self.parent) |p| self.rotation.add(p.rotation) else self.rotation;

        if (self.drawable) |d| try d.draw(renderer, pos, rot);
        for (self._children.items) |child| try child.update(renderer);
        if (self.lifecycle.postUpdate) |func| func(self);
    }

    pub fn deinit(self: *Object) !void {
        if (self.lifecycle.preClose) |func| func(self);

        if (self.drawable) |d| d.destroy();

        for (self._scripts.items) |script| script.end(self);
        self._scripts.deinit(std.heap.page_allocator);

        for (self._children.items) |child| try child.deinit();
        self._children.deinit(std.heap.page_allocator);

        if (self.lifecycle.postClose) |func| func(self);
    }

    pub fn getAbsPosition(self: *Object) types.common.Position {
        const parentPos = if (self.parent) |obj| obj.position else types.common.Position{};
        return self.position.add(parentPos);
    }

    pub fn setAbsPosition(self: *Object, pos: types.common.Position) void {
        const parentPos = if (self.parent) |obj| obj.position else types.common.Position{};
        self.position = pos.subtract(parentPos);
    }

    pub fn getAbsRotation(self: *Object) types.common.Rotation {
        const parentRot = if (self.parent) |obj| obj.rotation else types.common.Rotation{};
        return self.rotation.add(parentRot);
    }

    pub fn setAbsRotation(self: *Object, rot: types.common.Rotation) void {
        const parentRot = if (self.parent) |obj| obj.rotation else types.common.Rotation{};
        self.rotation = rot.subtract(parentRot);
    }

    pub fn addScript(self: *Object, script: *Script) !void {
        try self._scripts.append(std.heap.page_allocator, script);
    }

    pub fn setScene(self: *Object, scene: *Scene) void {
        self.scene = scene;
        for (self._children.items) |child| child.setScene(scene);
    }

    pub fn getChildByIndex(self: *Object, index: usize) *Object {
        return self._children.items[index];
    }

    pub fn attach(self: *Object, parent: *Object) void {
        if (self.parent) |_| self.detach();
        self.parent = parent;
        if (parent.scene) |s| self.setScene(s);
    }

    fn detach(self: *Object) void {
        const oldparent = self.parent;
        self.parent = null;
        if (oldparent) |p| p.rmvChild(self);
    }

    pub fn addChild(self: *Object, child: *Object) !void {
        try self._children.append(std.heap.page_allocator, child);
        child.attach(self);
    }

    pub fn rmvChild(self: *Object, child: *Object) void {
        var index: ?usize = undefined;
        for (self._children.items, 0..) |obj, i| {
            if (obj == child) {
                index = i;
                break;
            }
        }
        if (index) |i| {
            const c = self._children.orderedRemove(i);
            c.detach();
        }
    }
};

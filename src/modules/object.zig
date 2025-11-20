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

    _scene: ?*Scene = null,
    _parent: ?*Object = null,
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
    }) Object {
        return Object{
            .position = props.position,
            .rotation = props.rotation,
            .name = props.name,
            .tag = props.tag,
            .active = props.active,
            .drawable = props.drawable,
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

        const pos = if (self._parent) |p| self.position.add(p.position) else self.position;
        const rot = if (self._parent) |p| self.rotation.add(p.rotation) else self.rotation;

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

    pub fn setDrawable(self: *Object, drawable: *Drawable) void {
        if (self.drawable) |d| d.destroy();
        self.drawable = drawable;
    }

    pub fn getAbsPosition(self: *Object) types.common.Position {
        const parentPos = if (self._parent) |obj| obj.position else types.common.Position{};
        return self.position.add(parentPos);
    }

    pub fn setAbsPosition(self: *Object, pos: types.common.Position) void {
        const parentPos = if (self._parent) |obj| obj.position else types.common.Position{};
        self.position = pos.subtract(parentPos);
    }

    pub fn getAbsRotation(self: *Object) types.common.Rotation {
        const parentRot = if (self._parent) |obj| obj.rotation else types.common.Rotation{};
        return self.rotation.add(parentRot);
    }

    pub fn setAbsRotation(self: *Object, rot: types.common.Rotation) void {
        const parentRot = if (self._parent) |obj| obj.rotation else types.common.Rotation{};
        self.rotation = rot.subtract(parentRot);
    }

    pub fn addScript(self: *Object, script: *Script) !void {
        try self._scripts.append(std.heap.page_allocator, script);
    }

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

    pub fn attach(self: *Object, parent: *Object) void {
        if (self._parent) |_| self.detach();
        self._parent = parent;
        if (parent._scene) |s| self.setScene(s);
    }

    pub fn detach(self: *Object) void {
        const oldparent = self._parent;
        self._parent = null;
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

    pub fn getChildsByTag(self: *Object, tag: []const u8, comptime max: u8) []?*Object {
        var res: [max]?*Object = .{null} ** max;

        var i: u8 = 0;
        for (self._children.items) |c1| {
            if (i >= max) break;
            if (std.mem.eql(u8, c1.tag, tag)) res[i] = c1;
            i = i + 1;

            const inner_childs = c1.getChildsByTag(tag, max);
            for (inner_childs) |c2| {
                if (i >= max) break;
                if (c2) |_| {} else break;
                if (std.mem.eql(u8, c2.?.tag, tag)) res[i] = c2;
                i = i + 1;
            }
        }

        return res[0..i];
    }
};

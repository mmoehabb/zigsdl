const std = @import("std");
const sdl = @import("../sdl.zig");
const types = @import("../types/mod.zig");

const Scene = @import("./scene.zig").Scene;
const Drawable = @import("./drawable.zig").Drawable;
const Script = @import("./script.zig").Script;

pub const Object = struct {
    position: types.common.Position,
    rotation: types.common.Rotation,

    drawable: ?*const Drawable = null,
    scene: ?*Scene = null,
    parent: ?*Object = null,

    scripts: std.ArrayList(Script) = std.ArrayList(Script).empty,
    children: std.ArrayList(*Object) = std.ArrayList(*Object).empty,

    pub fn start(self: *Object) !void {
        for (self.scripts.items) |script| script.start(self);
        for (self.children.items) |child| try child.start();
    }

    pub fn update(self: *Object, renderer: *sdl.c.SDL_Renderer) !void {
        for (self.scripts.items) |script| script.update(self);
        const pos = if (self.parent) |p| self.position.add(p.position) else self.position;
        const rot = if (self.parent) |p| self.rotation.add(p.rotation) else self.rotation;
        if (self.drawable) |d| try d.draw(renderer, pos, rot);
        for (self.children.items) |child| try child.update(renderer);
    }

    pub fn deinit(self: *Object) !void {
        for (self.scripts.items) |script| script.end(self);
        self.scripts.deinit(std.heap.page_allocator);
        for (self.children.items) |child| try child.deinit();
        self.children.deinit(std.heap.page_allocator);
    }

    pub fn addScript(self: *Object, script: Script) !void {
        try self.scripts.append(std.heap.page_allocator, script);
    }

    pub fn setScene(self: *Object, scene: *Scene) void {
        self.scene = scene;
        for (self.children.items) |child| child.setScene(scene);
    }

    pub fn getChildByIndex(self: *Object, index: usize) *Object {
        return self.children.items[index];
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
        try self.children.append(std.heap.page_allocator, child);
        child.attach(self);
    }

    pub fn rmvChild(self: *Object, child: *Object) void {
        var index: ?usize = undefined;
        for (self.children.items, 0..) |obj, i| {
            if (obj == child) {
                index = i;
                break;
            }
        }
        if (index) |i| {
            const c = self.children.orderedRemove(i);
            c.detach();
        }
    }
};

const c = @cImport({
    @cInclude("SDL2/SDL.h");
});
const std = @import("std");

const Drawable = @import("./drawable.zig").Drawable;
const Script = @import("./script.zig").Script;
const Position = @import("../types/common.zig").Position;
const Rotation = @import("../types/common.zig").Rotation;

pub const Object = struct {
    position: Position,
    rotation: Rotation,
    drawable: *Drawable,

    _scripts: ?*std.ArrayList(Script),

    pub fn init(self: *Object) !*Object {
        if (self._scripts != undefined) return error.ObjectAlreadyInitialized;
        const gpa = std.heap.GeneralPurposeAllocator(.{}){};
        const allocator = gpa.allocator();
        self._scripts = std.ArrayList(Script).init(allocator);
        return self;
    }

    pub fn deinit(self: *Object) !void {
        for (self._scripts.?.items) |script| {
            if (script.end) |func| func();
        }
        self._scripts.deinit();
    }

    pub fn start(self: *Object) !void {
        for (self._scripts.?.items) |script| {
            if (script.start) |func| func();
        }
    }

    pub fn update(self: *Object, renderer: *c.SDL_Renderer) !void {
        for (self._scripts.?.items) |script| {
            if (script.update) |func| func();
        }
        try self.drawable.draw(renderer, self.position, self.rotation);
    }

    pub fn addScript(self: *Object, script: Script) !void {
        script.setObject(self);
        try self._scripts.?.addOne(script);
    }
};

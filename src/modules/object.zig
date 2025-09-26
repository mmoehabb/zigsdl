const c = @cImport({
    @cInclude("SDL2/SDL.h");
});
const ArrayList = @import("std").ArrayList;
const allocator = @import("std").mem.Allocator;

const Drawable = @import("./drawable.zig").Drawable;
const Script = @import("./script.zig").Script;
const Position = @import("../types/common.zig").Position;
const Rotation = @import("../types/common.zig").Rotation;

pub const Object = struct {
    position: Position,
    rotation: Rotation,

    drawable: *Drawable,
    scripts: ?*ArrayList(Script),

    pub fn init(self: *Object) !*Object {
        if (self.scripts != undefined) return error.ObjectAlreadyInitialized;
        self.scripts = ArrayList(Script).init(allocator);
        return self;
    }

    pub fn start(self: *Object) !void {
        for (self.scripts.?.items) |script| {
            if (script.start != undefined) script.start();
        }
    }

    pub fn update(self: *Object, renderer: *c.SDL_Renderer) !void {
        for (self.scripts.?.items) |script| {
            if (script.update != undefined) script.update();
        }
        try self.drawable.draw(renderer, self.position, self.rotation);
    }

    pub fn deinit(self: *Object) !void {
        for (self.scripts.?.items) |script| {
            if (script.end != undefined) script.end();
        }
        self.scripts.deinit();
    }

    pub fn addScript(self: *Object, script: Script) !void {
        script.setObject(self);
        try self.scripts.?.addOne(script);
    }
};

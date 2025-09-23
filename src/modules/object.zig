const c = @cImport({
    @cInclude("SDL2/SDL.h");
});

const Drawable = @import("./drawable.zig").Drawable;
const Position = @import("../types/common.zig").Position;
const Rotation = @import("../types/common.zig").Rotation;

pub const Object = struct {
    pos: Position,
    rot: Rotation,

    drawable: *Drawable,

    pub fn draw(self: *Object, renderer: *c.SDL_Renderer) !void {
        try self.drawable.draw(renderer, self.pos, self.rot);
    }
};

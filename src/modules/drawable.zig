const c = @cImport({
    @cInclude("SDL2/SDL.h");
});

const Position = @import("../types/common.zig").Position;
const Rotation = @import("../types/common.zig").Rotation;
const Color = @import("../types/common.zig").Color;

pub const Drawable = struct {
    width: isize,
    height: isize,
    depth: isize = 1,
    color: ?Color,

    pub fn draw(self: *Drawable, renderer: *c.SDL_Renderer, _: Position, _: Rotation) !void {
        if (self.color) |color| {
            _ = c.SDL_SetRenderDrawColor(renderer, color.r, color.g, color.b, color.a);
        }
    }
};

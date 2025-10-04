const sdl = @import("../sdl.zig");
const types = @import("../types/mod.zig");

pub const Drawable = struct {
    dim: types.common.Dimensions,
    drawFn: *const fn (_: *sdl.c.SDL_Renderer, _: types.common.Position, _: types.common.Rotation, _: types.common.Dimensions) void,
    color: ?types.common.Color,

    pub fn draw(self: Drawable, renderer: *sdl.c.SDL_Renderer, pos: types.common.Position, rot: types.common.Rotation) !void {
        if (self.color) |color| {
            _ = sdl.c.SDL_SetRenderDrawColor(renderer, color.r, color.g, color.b, color.a);
        }
        self.drawFn(renderer, pos, rot, self.dim);
    }
};

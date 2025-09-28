const c = @cImport({
    @cInclude("SDL3/SDL.h");
});

const Position = @import("../types/common.zig").Position;
const Rotation = @import("../types/common.zig").Rotation;
const Dimensions = @import("../types/common.zig").Dimensions;
const Color = @import("../types/common.zig").Color;

pub const Drawable = struct {
    dim: Dimensions,
    drawFn: *const fn (_: *c.SDL_Renderer, _: Position, _: Rotation, _: Dimensions) void,
    color: ?Color,

    pub fn draw(self: Drawable, renderer: *c.SDL_Renderer, pos: Position, rot: Rotation) !void {
        if (self.color) |color| {
            _ = c.SDL_SetRenderDrawColor(renderer, color.r, color.g, color.b, color.a);
        }
        self.drawFn(renderer, pos, rot, self.dim);
    }
};

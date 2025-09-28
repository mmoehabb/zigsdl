const c = @cImport({
    @cInclude("SDL3/SDL.h");
});
const Drawable = @import("../modules/drawable.zig").Drawable;
const Position = @import("../types/common.zig").Position;
const Rotation = @import("../types/common.zig").Rotation;
const Dimensions = @import("../types/common.zig").Dimensions;
const Color = @import("../types/common.zig").Color;

fn drawFn(renderer: *c.SDL_Renderer, p: Position, _: Rotation, dim: Dimensions) void {
    _ = c.SDL_RenderFillRect(renderer, &c.SDL_FRect{
        .x = p.x,
        .y = p.y,
        .w = dim.w,
        .h = dim.h,
    });
}

pub fn new(dim: Dimensions, color: Color) Drawable {
    return Drawable{
        .dim = dim,
        .color = color,
        .drawFn = drawFn,
    };
}

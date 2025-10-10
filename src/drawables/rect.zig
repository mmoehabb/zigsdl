const sdl = @import("../sdl.zig");
const modules = @import("../modules/mod.zig");
const types = @import("../types/mod.zig");

pub const Rect = struct {
    pub fn new(dim: types.common.Dimensions, color: types.common.Color) modules.Drawable {
        return modules.Drawable{
            .dim = dim,
            .color = color,
            .drawFn = &drawFn,
        };
    }

    fn drawFn(renderer: *sdl.c.SDL_Renderer, p: types.common.Position, _: types.common.Rotation, dim: types.common.Dimensions) void {
        _ = sdl.c.SDL_RenderFillRect(renderer, &sdl.c.SDL_FRect{
            .x = p.x,
            .y = p.y,
            .w = dim.w,
            .h = dim.h,
        });
    }
};

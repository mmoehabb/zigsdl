const sdl = @import("../sdl.zig");
const modules = @import("../modules/mod.zig");
const types = @import("../types/mod.zig");

pub const Rect = struct {
    dim: types.common.Dimensions,
    color: types.common.Color = .{},
    _draw_strategy: modules.DrawStrategy = modules.DrawStrategy{
        .draw = draw,
        .destroy = destroy,
    },

    pub fn new(dim: types.common.Dimensions, color: types.common.Color) Rect {
        return Rect{
            .dim = dim,
            .color = color,
        };
    }

    pub fn toDrawable(self: *Rect) modules.Drawable {
        return modules.Drawable{
            .dim = self.dim,
            .color = self.color,
            .drawStrategy = &self._draw_strategy,
        };
    }

    fn draw(
        _: *modules.Drawable,
        _: *const modules.DrawStrategy,
        renderer: *sdl.c.SDL_Renderer,
        p: types.common.Position,
        _: types.common.Rotation,
        dim: types.common.Dimensions,
    ) !void {
        if (!sdl.c.SDL_RenderFillRect(renderer, &sdl.c.SDL_FRect{
            .x = p.x,
            .y = p.y,
            .w = dim.w,
            .h = dim.h,
        })) return error.RenderFailed;
    }

    fn destroy(_: *modules.Drawable, _: *const modules.DrawStrategy) void {}
};

//! A concrete drawable to render a simple rectangle by using SDL_RenderGeometry.

const std = @import("std");
const sdl = @import("../sdl.zig");
const modules = @import("../modules/mod.zig");
const types = @import("../types/mod.zig");

const Rect = @This();

dim: types.Dimensions,
color: types.Color = .{},
_draw_strategy: modules.DrawStrategy = modules.DrawStrategy{
    .draw = draw,
    .destroy = destroy,
},

pub fn new(dim: types.Dimensions, color: types.Color) Rect {
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
    drawable: *modules.Drawable,
    _: *const modules.DrawStrategy,
    renderer: *sdl.c.SDL_Renderer,
    pos: types.Position,
    rot: types.Rotation,
    dim: types.Dimensions,
) !void {
    const color: sdl.c.SDL_FColor = .{
        .r = @floatFromInt(drawable.color.?.r),
        .g = @floatFromInt(drawable.color.?.g),
        .b = @floatFromInt(drawable.color.?.b),
        .a = @floatFromInt(drawable.color.?.a),
    };

    const center = .{
        .x = pos.x + (dim.w / 2),
        .y = pos.y + (dim.h / 2),
    };

    const angle = std.math.degreesToRadians(rot.z);
    const cos = @cos(angle);
    const sin = @sin(angle);

    const pa = sdl.c.SDL_Vertex{
        .position = .{
            .x = center.x + (dim.h / 2 * sin) - (dim.w / 2 * cos),
            .y = center.y - (dim.w / 2 * sin) - (dim.h / 2 * cos),
        },
        .color = color,
    };
    const pb = sdl.c.SDL_Vertex{
        .position = .{
            .x = pa.position.x - (dim.h * sin),
            .y = pa.position.y + (dim.h * cos),
        },
        .color = color,
    };
    const pc = sdl.c.SDL_Vertex{
        .position = .{
            .x = pa.position.x + (dim.w * cos),
            .y = pa.position.y + (dim.w * sin),
        },
        .color = color,
    };
    const pd = sdl.c.SDL_Vertex{
        .position = .{
            .x = pb.position.x + (dim.w * cos),
            .y = pb.position.y + (dim.w * sin),
        },
        .color = color,
    };
    const verts = [_]sdl.c.SDL_Vertex{ pa, pb, pc, pd };
    const indices = [_]c_int{ 0, 1, 2, 2, 1, 3 };

    if (!sdl.c.SDL_RenderGeometry(renderer, null, &verts, 4, &indices, 6)) {
        sdl.c.SDL_Log("Unable to render geometry: %s", sdl.c.SDL_GetError());
        return error.RenderFailed;
    }
}

fn destroy(_: *modules.Drawable, _: *const modules.DrawStrategy) void {}

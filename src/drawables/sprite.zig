//! A concrete drawable with facilities to render sprites/animations

const std = @import("std");
const sdl = @import("../sdl.zig");
const modules = @import("../modules/mod.zig");
const types = @import("../types/mod.zig");

const Sprite = @This();

/// The path of the sprite sheet file.
img_path: []const u8,

/// The number of frames of the animation.
frames_count: u32,

/// The width of each frame in pixels.
frame_width: f32,

/// The height of each frame in pixels.
frame_height: f32,

/// The gap beteen frames in pixels.
gap: f32 = 0,

/// Top margin of each frame (default, 0).
margin_top: f32 = 0,

/// The duration between rendering each frame and the next one (in milliseconds).
ms: u32 = 75,

/// The next frame, to be drawn, index (default, 0).
index: u32 = 0,

_texture: ?[*c]sdl.c.SDL_Texture = null,
_draw_strategy: modules.DrawStrategy = .{
    .draw = draw,
    .destroy = destroy,
},
_last_ticks: u64 = 0,

pub fn new(s: Sprite) Sprite {
    return Sprite{
        .img_path = s.img_path,
        .frames_count = s.frames_count,
        .frame_width = s.frame_width,
        .frame_height = s.frame_height,
        .margin_top = s.margin_top,
        .gap = s.gap,
        .ms = s.ms,
    };
}

pub fn toDrawable(
    self: *Sprite,
    dim: types.Dimensions,
    color: types.Color,
) modules.Drawable {
    return modules.Drawable{
        .dim = dim,
        .color = color,
        .drawStrategy = &self._draw_strategy,
    };
}

pub fn setImgPath(self: *Sprite, img_path: []const u8) void {
    self.img_path = img_path;
    self._texture = null;
}

fn draw(
    _: *modules.Drawable,
    ds: *const modules.DrawStrategy,
    renderer: *sdl.c.SDL_Renderer,
    pos: types.Position,
    rot: types.Rotation,
    dim: types.Dimensions,
) !void {
    const self = @as(*Sprite, @constCast(@fieldParentPtr("_draw_strategy", ds)));

    const texture = self._texture orelse blk: {
        const surface = sdl.c.IMG_Load(self.img_path.ptr);
        defer sdl.c.SDL_DestroySurface(surface);
        const texture = sdl.c.SDL_CreateTextureFromSurface(renderer, surface);
        break :blk texture;
    };

    const src = sdl.c.SDL_FRect{
        .x = (@as(f32, @floatFromInt(self.index)) * self.frame_width) + self.gap,
        .y = 0,
        .w = self.frame_width,
        .h = self.frame_height,
    };
    const dest = sdl.c.SDL_FRect{
        .x = pos.x,
        .y = pos.y,
        .w = dim.w,
        .h = dim.h,
    };
    const center = sdl.c.SDL_FPoint{
        .x = dim.w / 2,
        .y = dim.h / 2,
    };
    const flip: c_uint = blk: {
        if (rot.x > 0) break :blk sdl.c.SDL_FLIP_VERTICAL;
        if (rot.y > 0) break :blk sdl.c.SDL_FLIP_HORIZONTAL;
        break :blk sdl.c.SDL_FLIP_NONE;
    };

    if (!sdl.c.SDL_RenderTextureRotated(
        renderer,
        texture,
        &src,
        &dest,
        rot.z,
        &center,
        flip,
    )) return error.RenderFailed;

    if (sdl.c.SDL_GetTicks() - self._last_ticks >= self.ms) {
        self.index = if (self.index >= self.frames_count) 0 else self.index + 1;
        self._last_ticks = sdl.c.SDL_GetTicks();
    }
}

fn destroy(_: *modules.Drawable, ds: *const modules.DrawStrategy) void {
    const self = @as(*Sprite, @constCast(@fieldParentPtr("_draw_strategy", ds)));
    if (self._texture) |t| sdl.c.SDL_DestroyTexture(t);
}

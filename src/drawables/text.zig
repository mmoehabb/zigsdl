//! This component can be used to render text on screen

const sdl = @import("../sdl.zig");
const std = @import("std");
const modules = @import("../modules/mod.zig");
const types = @import("../types/mod.zig");

pub const Text = struct {
    text: []const u8,
    font_path: []const u8,
    font_size: f32,
    color: types.common.Color = .{ .b = 255, .g = 255, .r = 255 },

    _texture: ?[*c]sdl.c.SDL_Texture = null,
    _draw_strategy: modules.DrawStrategy = .{
        .draw = draw,
        .destroy = destroy,
    },

    pub fn new(t: Text) Text {
        return Text{
            .text = t.text,
            .font_path = t.font_path,
            .font_size = t.font_size,
            .color = .{ .r = 255, .g = 255, .b = 255 },
        };
    }

    pub fn toDrawable(self: *Text) modules.Drawable {
        return modules.Drawable{
            .dim = .{ .w = 0, .h = 0, .d = 0 },
            .color = self.color,
            .drawStrategy = &self._draw_strategy,
        };
    }

    pub fn getDim(self: *Text) types.common.Dimensions {
        return .{
            .w = if (self._texture) |t| @floatFromInt(t.*.w) else 0,
            .h = if (self._texture) |t| @floatFromInt(t.*.h) else 0,
            .d = 1,
        };
    }

    fn draw(
        drawable: *modules.Drawable,
        ds: *const modules.DrawStrategy,
        renderer: *sdl.c.SDL_Renderer,
        pos: types.common.Position,
        _: types.common.Rotation,
        _: types.common.Dimensions,
    ) !void {
        const self = @as(*Text, @constCast(@fieldParentPtr("_draw_strategy", ds)));

        const texture = self._texture orelse blk: {
            const font = sdl.c.TTF_OpenFont(self.font_path.ptr, self.font_size);
            const surface = sdl.c.TTF_RenderText_Solid(font, self.text.ptr, self.text.len, sdl.c.SDL_Color{
                .a = self.*.color.a,
                .b = self.*.color.b,
                .g = self.*.color.g,
                .r = self.*.color.r,
            });
            defer sdl.c.SDL_DestroySurface(surface);
            const texture = sdl.c.SDL_CreateTextureFromSurface(renderer, surface);
            break :blk texture;
        };

        const dest = sdl.c.SDL_FRect{
            .x = pos.x,
            .y = pos.y,
            .w = @as(f32, @floatFromInt(texture.*.w)),
            .h = @as(f32, @floatFromInt(texture.*.h)),
        };
        if (!sdl.c.SDL_RenderTexture(
            renderer,
            texture,
            null,
            &dest,
        )) return error.RenderFailed;

        drawable.setDim(.{
            .w = @as(f32, @floatFromInt(texture.*.w)),
            .h = @as(f32, @floatFromInt(texture.*.h)),
            .d = 1,
        });
    }

    fn destroy(_: *modules.Drawable, ds: *const modules.DrawStrategy) void {
        const self = @as(*Text, @constCast(@fieldParentPtr("_draw_strategy", ds)));
        if (self._texture) |t| sdl.c.SDL_DestroyTexture(t);
    }
};

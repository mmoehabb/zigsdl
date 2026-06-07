//! A concrete drawable to render a simple clickable button by using SDL_RenderGeometry for the
//! background and SDL_TTF for the label.

const std = @import("std");
const sdl = @import("../sdl.zig");
const modules = @import("../modules/mod.zig");
const types = @import("../types/mod.zig");

const Button = @This();

const State = enum { Idle, Hover, Pressed };

label: []const u8,
dim: types.Dimensions,
color: types.Color = .{ .r = 200, .g = 200, .b = 200 },
hover_color: types.Color = .{ .r = 220, .g = 220, .b = 220 },
pressed_color: types.Color = .{ .r = 160, .g = 160, .b = 160 },
text_color: types.Color = .{ .r = 0, .g = 0, .b = 0 },
font_path: []const u8,
font_size: f32 = 16,

/// Invoked whenever the button is clicked (mouse up while previously pressed inside the bounds).
on_click: ?*const fn (self: *Button) void = null,

_state: State = .Idle,
_prev_mouse_down: bool = false,
_texture: ?[*c]sdl.c.SDL_Texture = null,
_last_label: []const u8 = "",
_last_color: types.Color = .{},

_draw_strategy: modules.DrawStrategy = modules.DrawStrategy{
    .draw = draw,
    .destroy = destroy,
},

pub fn new(b: Button) Button {
    return Button{
        .label = b.label,
        .dim = b.dim,
        .color = b.color,
        .hover_color = b.hover_color,
        .pressed_color = b.pressed_color,
        .text_color = b.text_color,
        .font_path = b.font_path,
        .font_size = b.font_size,
        .on_click = b.on_click,
    };
}

pub fn toDrawable(self: *Button) modules.Drawable {
    return modules.Drawable{
        .dim = self.dim,
        .color = self.color,
        .drawStrategy = &self._draw_strategy,
    };
}

pub fn setLabel(self: *Button, label: []const u8) void {
    self.label = label;
    self._texture = null;
}

fn fillRect(renderer: *sdl.c.SDL_Renderer, pos: types.Position, dim: types.Dimensions, color: types.Color) !void {
    const fc: sdl.c.SDL_FColor = .{
        .r = @floatFromInt(color.r),
        .g = @floatFromInt(color.g),
        .b = @floatFromInt(color.b),
        .a = @floatFromInt(color.a),
    };

    const center = .{
        .x = pos.x + (dim.w / 2),
        .y = pos.y + (dim.h / 2),
    };

    const pa = sdl.c.SDL_Vertex{
        .position = .{ .x = pos.x, .y = pos.y },
        .color = fc,
    };
    const pb = sdl.c.SDL_Vertex{
        .position = .{ .x = pos.x, .y = pos.y + dim.h },
        .color = fc,
    };
    const pc = sdl.c.SDL_Vertex{
        .position = .{ .x = pos.x + dim.w, .y = pos.y },
        .color = fc,
    };
    const pd = sdl.c.SDL_Vertex{
        .position = .{ .x = pos.x + dim.w, .y = pos.y + dim.h },
        .color = fc,
    };
    const verts = [_]sdl.c.SDL_Vertex{ pa, pb, pc, pd };
    const indices = [_]c_int{ 0, 1, 2, 2, 1, 3 };

    _ = center;
    if (!sdl.c.SDL_RenderGeometry(renderer, null, &verts, 4, &indices, 6)) {
        sdl.c.SDL_Log("Button: unable to render geometry: %s", sdl.c.SDL_GetError());
        return error.RenderFailed;
    }
}

fn draw(
    _: *modules.Drawable,
    ds: *const modules.DrawStrategy,
    renderer: *sdl.c.SDL_Renderer,
    pos: types.Position,
    _: types.Rotation,
    dim: types.Dimensions,
) !void {
    const self = @as(*Button, @constCast(@fieldParentPtr("_draw_strategy", ds)));

    var em = modules.Globals.eventManager.?;
    em.refreshMouseFromSDL();
    const mouse_pos = em.getMousePos();
    const mouse_down = em.isMouseDown();

    const inside = mouse_pos.x >= pos.x and mouse_pos.x <= pos.x + dim.w and
        mouse_pos.y >= pos.y and mouse_pos.y <= pos.y + dim.h;

    if (inside) {
        if (mouse_down) {
            self._state = .Pressed;
        } else {
            if (self._state == .Pressed and self._prev_mouse_down) {
                if (self.on_click) |cb| cb(self);
            }
            self._state = .Hover;
        }
    } else {
        self._state = .Idle;
    }
    self._prev_mouse_down = mouse_down and inside;

    const fill_color = switch (self._state) {
        .Idle => self.color,
        .Hover => self.hover_color,
        .Pressed => self.pressed_color,
    };

    try fillRect(renderer, pos, dim, fill_color);

    const text_changed = self._texture == null or
        !std.mem.eql(u8, self._last_label, self.label) or
        !std.meta.eql(self._last_color, self.text_color);
    if (text_changed) {
        if (self._texture) |t| sdl.c.SDL_DestroyTexture(t);
        const font = sdl.c.TTF_OpenFont(self.font_path.ptr, self.font_size);
        if (font == null) return error.RenderFailed;
        defer sdl.c.TTF_CloseFont(font);
        const surface = sdl.c.TTF_RenderText_Blended(font, self.label.ptr, self.label.len, sdl.c.SDL_Color{
            .a = self.text_color.a,
            .b = self.text_color.b,
            .g = self.text_color.g,
            .r = self.text_color.r,
        });
        if (surface == null) return error.RenderFailed;
        defer sdl.c.SDL_DestroySurface(surface);
        self._texture = sdl.c.SDL_CreateTextureFromSurface(renderer, surface);
        if (self._texture) |tex| {
            _ = sdl.c.SDL_SetTextureScaleMode(tex, sdl.c.SDL_SCALEMODE_LINEAR);
        } else return error.RenderFailed;
        self._last_label = self.label;
        self._last_color = self.text_color;
    }

    if (self._texture) |t| {
        const tw: f32 = @floatFromInt(t.*.w);
        const th: f32 = @floatFromInt(t.*.h);
        const dest = sdl.c.SDL_FRect{
            .x = pos.x + (dim.w - tw) / 2,
            .y = pos.y + (dim.h - th) / 2,
            .w = tw,
            .h = th,
        };
        if (!sdl.c.SDL_RenderTexture(renderer, t, null, &dest)) {
            return error.RenderFailed;
        }
    }
}

fn destroy(_: *modules.Drawable, ds: *const modules.DrawStrategy) void {
    const self = @as(*Button, @constCast(@fieldParentPtr("_draw_strategy", ds)));
    if (self._texture) |t| sdl.c.SDL_DestroyTexture(t);
}

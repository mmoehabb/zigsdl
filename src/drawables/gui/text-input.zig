//! A concrete drawable to render a text input field. It uses SDL_TTF for rendering
//! the typed text and SDL's text-input facilities for capturing unicode characters.

const std = @import("std");
const sdl = @import("../../sdl.zig");
const modules = @import("../../modules/mod.zig");
const types = @import("../../types/mod.zig");

const TextInput = @This();

const State = enum { Idle, Hover, Pressed, Focused };

placeholder: []const u8 = "",
dim: types.Dimensions,
bg_color: types.Color = .{ .r = 255, .g = 255, .b = 255 },
border_color: types.Color = .{ .r = 180, .g = 180, .b = 180 },
focused_border_color: types.Color = .{ .r = 30, .g = 144, .b = 255 },
text_color: types.Color = .{ .r = 0, .g = 0, .b = 0 },
placeholder_color: types.Color = .{ .r = 160, .g = 160, .b = 160 },
font_path: []const u8,
font_size: f32 = 16,
max_len: usize = 256,

_allocator: std.mem.Allocator = undefined,

/// Length of the text currently held in the internal buffer. See [getText](#root.drawables.textinput.gettext).
len: usize = 0,

/// Mutable: true while the field has input focus.
focused: bool = false,

/// Invoked whenever the text content changes.
on_change: ?*const fn (self: *TextInput) void = null,

_state: State = .Idle,
_prev_mouse_down_inside: bool = false,
_prev_mouse_down_outside: bool = false,
_text_input_active: bool = false,
_prev_bs_down: bool = false,
_texture: ?[*c]sdl.c.SDL_Texture = null,
_last_rendered: []const u8 = "",
_last_color: types.Color = .{},
_text: []u8 = &[_]u8{},

_draw_strategy: modules.DrawStrategy = modules.DrawStrategy{
    .draw = draw,
    .destroy = destroy,
},

pub fn new(allocator: std.mem.Allocator, t: TextInput) !TextInput {
    const buf = try allocator.alloc(u8, t.max_len + 1);
    @memset(buf, 0);
    return TextInput{
        .placeholder = t.placeholder,
        .dim = t.dim,
        .bg_color = t.bg_color,
        .border_color = t.border_color,
        .focused_border_color = t.focused_border_color,
        .text_color = t.text_color,
        .placeholder_color = t.placeholder_color,
        .font_path = t.font_path,
        .font_size = t.font_size,
        .max_len = t.max_len,
        ._allocator = allocator,
        ._text = buf,
        .on_change = t.on_change,
    };
}

pub fn toDrawable(self: *TextInput) modules.Drawable {
    return modules.Drawable{
        .dim = self.dim,
        .color = self.bg_color,
        .drawStrategy = &self._draw_strategy,
    };
}

pub fn getText(self: *TextInput) []const u8 {
    return self._text[0..self.len];
}

pub fn setText(self: *TextInput, str: []const u8) void {
    const n = @min(str.len, self.max_len);
    @memcpy(self._text[0..n], str[0..n]);
    self._text[n] = 0;
    self.len = n;
    self._texture = null;
}

fn fillRect(renderer: *sdl.c.SDL_Renderer, x: f32, y: f32, w: f32, h: f32, color: types.Color) !void {
    const fc: sdl.c.SDL_FColor = .{
        .r = @floatFromInt(color.r),
        .g = @floatFromInt(color.g),
        .b = @floatFromInt(color.b),
        .a = @floatFromInt(color.a),
    };
    const verts = [_]sdl.c.SDL_Vertex{
        .{ .position = .{ .x = x, .y = y }, .color = fc },
        .{ .position = .{ .x = x, .y = y + h }, .color = fc },
        .{ .position = .{ .x = x + w, .y = y }, .color = fc },
        .{ .position = .{ .x = x + w, .y = y + h }, .color = fc },
    };
    const indices = [_]c_int{ 0, 1, 2, 2, 1, 3 };
    if (!sdl.c.SDL_RenderGeometry(renderer, null, &verts, 4, &indices, 6)) {
        sdl.c.SDL_Log("TextInput: unable to render geometry: %s", sdl.c.SDL_GetError());
        return error.RenderFailed;
    }
}

fn strokeRect(renderer: *sdl.c.SDL_Renderer, x: f32, y: f32, w: f32, h: f32, color: types.Color, t: f32) !void {
    try fillRect(renderer, x, y, w, t, color);
    try fillRect(renderer, x, y + h - t, w, t, color);
    try fillRect(renderer, x, y, t, h, color);
    try fillRect(renderer, x + w - t, y, t, h, color);
}

fn draw(
    _: *modules.Drawable,
    ds: *const modules.DrawStrategy,
    renderer: *sdl.c.SDL_Renderer,
    pos: types.Position,
    _: types.Rotation,
    dim: types.Dimensions,
) !void {
    const self = @as(*TextInput, @constCast(@fieldParentPtr("_draw_strategy", ds)));

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
            if (self._prev_mouse_down_inside) {
                self.focused = true;
            }
            self._state = if (self.focused) .Focused else .Hover;
        }
    } else {
        if (mouse_down) {
            self._state = .Idle;
        } else {
            if (self._prev_mouse_down_outside) {
                self.focused = false;
            }
            self._state = .Idle;
        }
    }
    self._prev_mouse_down_inside = mouse_down and inside;
    self._prev_mouse_down_outside = mouse_down and !inside;

    if (self.focused) {
        if (!self._text_input_active) {
            _ = sdl.c.SDL_StartTextInput(null);
            self._text_input_active = true;
        }

        const typed = em.drainTextInput();
        if (typed.len > 0) {
            const cap = self.max_len - self.len;
            const take = @min(typed.len, cap);
            if (take > 0) {
                @memcpy(self._text[self.len..][0..take], typed[0..take]);
                self.len += take;
                self._text[self.len] = 0;
                self._texture = null;
                if (self.on_change) |cb| cb(self);
            }
        }

        const bs_down = em.isKeyDown(.Backspace);
        if (bs_down and !self._prev_bs_down and self.len > 0) {
            const removed_len = utf8BackOne(self._text[0..self.len]);
            self.len -= removed_len;
            self._text[self.len] = 0;
            self._texture = null;
            if (self.on_change) |cb| cb(self);
        }
        self._prev_bs_down = bs_down;
    } else if (self._text_input_active) {
        _ = sdl.c.SDL_StopTextInput(null);
        self._text_input_active = false;
    }

    const border_thickness: f32 = @max(1.0, @min(dim.w, dim.h) * 0.04);
    const inner_x = pos.x + border_thickness;
    const inner_y = pos.y + border_thickness;
    const inner_w = dim.w - 2 * border_thickness;
    const inner_h = dim.h - 2 * border_thickness;

    try fillRect(renderer, inner_x, inner_y, inner_w, inner_h, self.bg_color);

    const border = if (self._state == .Focused) self.focused_border_color else self.border_color;
    try strokeRect(renderer, pos.x, pos.y, dim.w, dim.h, border, border_thickness);

    const show_placeholder = self.len == 0 and self.placeholder.len > 0;
    const show_text = self.len > 0;

    if (show_placeholder or show_text) {
        const draw_str: []const u8 = if (show_placeholder) self.placeholder else self._text[0..self.len];
        const draw_color: types.Color = if (show_placeholder) self.placeholder_color else self.text_color;

        const text_changed = self._texture == null or
            !std.mem.eql(u8, self._last_rendered, draw_str) or
            !std.meta.eql(self._last_color, draw_color);
        if (text_changed) {
            if (self._texture) |tex| sdl.c.SDL_DestroyTexture(tex);
            const font = sdl.c.TTF_OpenFont(self.font_path.ptr, self.font_size);
            if (font == null) return error.RenderFailed;
            defer sdl.c.TTF_CloseFont(font);
            const surface = sdl.c.TTF_RenderText_Blended(font, draw_str.ptr, draw_str.len, sdl.c.SDL_Color{
                .a = draw_color.a,
                .b = draw_color.b,
                .g = draw_color.g,
                .r = draw_color.r,
            });
            if (surface == null) return error.RenderFailed;
            defer sdl.c.SDL_DestroySurface(surface);
            self._texture = sdl.c.SDL_CreateTextureFromSurface(renderer, surface);
            if (self._texture) |tex| {
                _ = sdl.c.SDL_SetTextureScaleMode(tex, sdl.c.SDL_SCALEMODE_LINEAR);
            } else return error.RenderFailed;
            self._last_rendered = draw_str;
            self._last_color = draw_color;
        }

        if (self._texture) |tex| {
            const th: f32 = @floatFromInt(tex.*.h);
            const dest = sdl.c.SDL_FRect{
                .x = inner_x + 4,
                .y = inner_y + (inner_h - th) / 2,
                .w = @floatFromInt(tex.*.w),
                .h = th,
            };
            if (!sdl.c.SDL_RenderTexture(renderer, tex, null, &dest)) {
                return error.RenderFailed;
            }
        }
    }

    if (self._state == .Focused) {
        const ticks: u64 = sdl.c.SDL_GetTicks();
        if (ticks % 1000 < 500) {
            const caret_x = if (self._texture) |tex|
                inner_x + 4 + @as(f32, @floatFromInt(tex.*.w)) + 1
            else
                inner_x + 4;
            const caret_h = self.font_size;
            const caret_y = inner_y + (inner_h - caret_h) / 2;
            try fillRect(renderer, caret_x, caret_y, 1.5, caret_h, self.text_color);
        }
    }
}

fn utf8BackOne(s: []const u8) usize {
    var i: usize = s.len;
    while (i > 0) {
        i -= 1;
        if ((s[i] & 0xC0) != 0x80) {
            return s.len - i;
        }
        if (i == 0) break;
    }
    return s.len;
}

fn destroy(_: *modules.Drawable, ds: *const modules.DrawStrategy) void {
    const self = @as(*TextInput, @constCast(@fieldParentPtr("_draw_strategy", ds)));
    if (self._text_input_active) _ = sdl.c.SDL_StopTextInput(null);
    if (self._texture) |t| sdl.c.SDL_DestroyTexture(t);
    self._allocator.free(self._text);
}

//! A concrete drawable to render a select/dropdown widget. The trigger shows the
//! currently selected option; clicking it opens a dropdown panel of all options.

const std = @import("std");
const sdl = @import("../../sdl.zig");
const modules = @import("../../modules/mod.zig");
const types = @import("../../types/mod.zig");

const Select = @This();

const State = enum { Idle, Hover, Open };

/// The list of selectable options. The slice itself must outlive the drawable.
options: []const []const u8,
dim: types.Dimensions,
bg_color: types.Color = .{ .r = 245, .g = 245, .b = 245 },
hover_color: types.Color = .{ .r = 230, .g = 230, .b = 240 },
open_color: types.Color = .{ .r = 220, .g = 220, .b = 235 },
option_hover_color: types.Color = .{ .r = 200, .g = 215, .b = 240 },
border_color: types.Color = .{ .r = 180, .g = 180, .b = 180 },
text_color: types.Color = .{ .r = 0, .g = 0, .b = 0 },
font_path: []const u8,
font_size: f32 = 16,

/// Mutable: index of the currently selected option, or null if none is selected.
selected_index: ?usize = null,

/// Invoked whenever the selected option changes.
on_change: ?*const fn (self: *Select) void = null,

_allocator: std.mem.Allocator = undefined,
_state: State = .Idle,
_open: bool = false,
_hover_option: ?usize = null,
_prev_mouse_down_inside_trigger: bool = false,
_prev_mouse_down_inside_dropdown: bool = false,
_trigger_texture: ?[*c]sdl.c.SDL_Texture = null,
_last_trigger_text: []const u8 = "",
_option_textures: std.ArrayList(?[*c]sdl.c.SDL_Texture) = .empty,
_built: bool = false,

_draw_strategy: modules.DrawStrategy = modules.DrawStrategy{
    .draw = draw,
    .destroy = destroy,
},

pub fn new(allocator: std.mem.Allocator, s: Select) !Select {
    return Select{
        .options = s.options,
        .dim = s.dim,
        .bg_color = s.bg_color,
        .hover_color = s.hover_color,
        .open_color = s.open_color,
        .option_hover_color = s.option_hover_color,
        .border_color = s.border_color,
        .text_color = s.text_color,
        .font_path = s.font_path,
        .font_size = s.font_size,
        .selected_index = s.selected_index,
        .on_change = s.on_change,
        ._allocator = allocator,
    };
}

pub fn toDrawable(self: *Select) modules.Drawable {
    return modules.Drawable{
        .dim = self.dim,
        .color = self.bg_color,
        .drawStrategy = &self._draw_strategy,
    };
}

pub fn getSelected(self: *Select) ?[]const u8 {
    if (self.selected_index) |i| {
        if (i < self.options.len) return self.options[i];
    }
    return null;
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
        sdl.c.SDL_Log("Select: unable to render geometry: %s", sdl.c.SDL_GetError());
        return error.RenderFailed;
    }
}

fn strokeRect(renderer: *sdl.c.SDL_Renderer, x: f32, y: f32, w: f32, h: f32, color: types.Color, t: f32) !void {
    try fillRect(renderer, x, y, w, t, color);
    try fillRect(renderer, x, y + h - t, w, t, color);
    try fillRect(renderer, x, y, t, h, color);
    try fillRect(renderer, x + w - t, y, t, h, color);
}

fn renderText(renderer: *sdl.c.SDL_Renderer, font_path: []const u8, font_size: f32, str: []const u8, color: types.Color) ![*c]sdl.c.SDL_Texture {
    const font = sdl.c.TTF_OpenFont(font_path.ptr, font_size);
    if (font == null) return error.RenderFailed;
    defer sdl.c.TTF_CloseFont(font);
    const surface = sdl.c.TTF_RenderText_Blended(font, str.ptr, str.len, sdl.c.SDL_Color{
        .a = color.a,
        .b = color.b,
        .g = color.g,
        .r = color.r,
    });
    if (surface == null) return error.RenderFailed;
    defer sdl.c.SDL_DestroySurface(surface);
    const tex = sdl.c.SDL_CreateTextureFromSurface(renderer, surface);
    if (tex == null) return error.RenderFailed;
    _ = sdl.c.SDL_SetTextureScaleMode(tex, sdl.c.SDL_SCALEMODE_LINEAR);
    return tex;
}

fn buildOptionTextures(self: *Select, renderer: *sdl.c.SDL_Renderer) !void {
    while (self._option_textures.items.len < self.options.len) {
        self._option_textures.append(self._allocator, null) catch return error.RenderFailed;
    }
    for (self.options, 0..) |opt, i| {
        if (self._option_textures.items[i] == null) {
            self._option_textures.items[i] = try renderText(
                renderer,
                self.font_path,
                self.font_size,
                opt,
                self.text_color,
            );
        }
    }
    self._built = true;
}

fn draw(
    _: *modules.Drawable,
    ds: *const modules.DrawStrategy,
    renderer: *sdl.c.SDL_Renderer,
    pos: types.Position,
    _: types.Rotation,
    dim: types.Dimensions,
) !void {
    const self = @as(*Select, @constCast(@fieldParentPtr("_draw_strategy", ds)));

    if (!self._built) try self.buildOptionTextures(renderer);

    var em = modules.Globals.getAll().eventManager;
    const mouse_pos = em.getMousePos();
    const mouse_down = em.isMouseDown();

    const trigger_inside = mouse_pos.x >= pos.x and mouse_pos.x <= pos.x + dim.w and
        mouse_pos.y >= pos.y and mouse_pos.y <= pos.y + dim.h;

    const dropdown_top = pos.y + dim.h;
    var dropdown_inside = false;
    var option_idx: ?usize = null;
    if (self._open) {
        for (self.options, 0..) |_, i| {
            const oy = dropdown_top + @as(f32, @floatFromInt(i)) * dim.h;
            if (mouse_pos.x >= pos.x and mouse_pos.x <= pos.x + dim.w and
                mouse_pos.y >= oy and mouse_pos.y <= oy + dim.h)
            {
                dropdown_inside = true;
                option_idx = i;
                break;
            }
        }
    }

    if (self._open) {
        if (trigger_inside or dropdown_inside) {
            if (mouse_down) {
                self._state = .Open;
            } else {
                if (self._prev_mouse_down_inside_dropdown and option_idx != null) {
                    const new_idx = option_idx.?;
                    if (self.selected_index != new_idx) {
                        self.selected_index = new_idx;
                        if (self.on_change) |cb| cb(self);
                    }
                    self._open = false;
                    self._hover_option = null;
                } else if (self._prev_mouse_down_inside_trigger) {
                    self._open = false;
                    self._hover_option = null;
                } else {
                    self._hover_option = option_idx;
                }
                self._state = .Open;
            }
        } else {
            if (!mouse_down and (self._prev_mouse_down_inside_trigger or self._prev_mouse_down_inside_dropdown)) {
                self._open = false;
                self._hover_option = null;
            }
            self._state = if (self._open) .Open else .Idle;
        }
    } else {
        if (trigger_inside) {
            if (mouse_down) {
                self._state = .Hover;
            } else {
                if (self._prev_mouse_down_inside_trigger) {
                    self._open = true;
                    self._state = .Open;
                } else {
                    self._state = .Hover;
                }
            }
        } else {
            self._state = .Idle;
        }
    }
    self._prev_mouse_down_inside_trigger = mouse_down and trigger_inside;
    self._prev_mouse_down_inside_dropdown = mouse_down and dropdown_inside;

    const trigger_fill: types.Color = switch (self._state) {
        .Idle => self.bg_color,
        .Hover => self.hover_color,
        .Open => self.open_color,
    };
    try fillRect(renderer, pos.x, pos.y, dim.w, dim.h, trigger_fill);
    const border_t: f32 = @max(1.0, @min(dim.w, dim.h) * 0.04);
    try strokeRect(renderer, pos.x, pos.y, dim.w, dim.h, self.border_color, border_t);

    const trigger_text: []const u8 = if (self.getSelected()) |s| s else "Select...";
    if (self._trigger_texture == null or !std.mem.eql(u8, self._last_trigger_text, trigger_text)) {
        if (self._trigger_texture) |t| sdl.c.SDL_DestroyTexture(t);
        self._trigger_texture = try renderText(
            renderer,
            self.font_path,
            self.font_size,
            trigger_text,
            self.text_color,
        );
        self._last_trigger_text = trigger_text;
    }

    if (self._trigger_texture) |t| {
        const th: f32 = @floatFromInt(t.*.h);
        const dest = sdl.c.SDL_FRect{
            .x = pos.x + 6,
            .y = pos.y + (dim.h - th) / 2,
            .w = @floatFromInt(t.*.w),
            .h = th,
        };
        if (!sdl.c.SDL_RenderTexture(renderer, t, null, &dest)) return error.RenderFailed;
    }

    const arrow_size: f32 = @min(dim.w, dim.h) * 0.25;
    const arrow_cx = pos.x + dim.w - arrow_size - 6;
    const arrow_cy = pos.y + dim.h / 2;
    _ = sdl.c.SDL_SetRenderDrawColor(renderer, self.text_color.r, self.text_color.g, self.text_color.b, self.text_color.a);
    if (!sdl.c.SDL_RenderLine(
        renderer,
        arrow_cx - arrow_size / 2,
        arrow_cy - arrow_size / 4,
        arrow_cx,
        arrow_cy + arrow_size / 4,
    )) return error.RenderFailed;
    if (!sdl.c.SDL_RenderLine(
        renderer,
        arrow_cx,
        arrow_cy + arrow_size / 4,
        arrow_cx + arrow_size / 2,
        arrow_cy - arrow_size / 4,
    )) return error.RenderFailed;

    if (self._open) {
        for (self.options, 0..) |_, i| {
            const oy = dropdown_top + @as(f32, @floatFromInt(i)) * dim.h;
            const hover = self._hover_option == i;
            const is_selected = self.selected_index == i;
            const fill: types.Color = if (is_selected)
                self.option_hover_color
            else if (hover)
                self.option_hover_color
            else
                self.bg_color;
            try fillRect(renderer, pos.x, oy, dim.w, dim.h, fill);
            try strokeRect(renderer, pos.x, oy, dim.w, dim.h, self.border_color, border_t);

            if (i < self._option_textures.items.len) {
                if (self._option_textures.items[i]) |tex| {
                    const th: f32 = @floatFromInt(tex.*.h);
                    const dest = sdl.c.SDL_FRect{
                        .x = pos.x + 6,
                        .y = oy + (dim.h - th) / 2,
                        .w = @floatFromInt(tex.*.w),
                        .h = th,
                    };
                    if (!sdl.c.SDL_RenderTexture(renderer, tex, null, &dest)) return error.RenderFailed;
                }
            }
        }
    }
}

fn destroy(_: *modules.Drawable, ds: *const modules.DrawStrategy) void {
    const self = @as(*Select, @constCast(@fieldParentPtr("_draw_strategy", ds)));
    if (self._trigger_texture) |t| sdl.c.SDL_DestroyTexture(t);
    for (self._option_textures.items) |maybe_t| {
        if (maybe_t) |t| sdl.c.SDL_DestroyTexture(t);
    }
    self._option_textures.deinit(self._allocator);
}

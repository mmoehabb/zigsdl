//! A concrete drawable to render a checkbox by using SDL_RenderGeometry for the box
//! and SDL_RenderLine for the check mark.

const std = @import("std");
const sdl = @import("../sdl.zig");
const modules = @import("../modules/mod.zig");
const types = @import("../types/mod.zig");

const CheckBox = @This();

const State = enum { Idle, Hover, Pressed };

/// Mutable: click toggles this. Read it from user code to query the state.
checked: bool = false,

dim: types.Dimensions,
box_color: types.Color = .{ .r = 240, .g = 240, .b = 240 },
hover_color: types.Color = .{ .r = 220, .g = 220, .b = 255 },
check_color: types.Color = .{ .r = 30, .g = 144, .b = 255 },

/// Invoked whenever the checkbox toggles state.
on_toggle: ?*const fn (self: *CheckBox) void = null,

_state: State = .Idle,
_prev_mouse_down: bool = false,
_draw_strategy: modules.DrawStrategy = modules.DrawStrategy{
    .draw = draw,
    .destroy = destroy,
},

pub fn new(c: CheckBox) CheckBox {
    return CheckBox{
        .checked = c.checked,
        .dim = c.dim,
        .box_color = c.box_color,
        .hover_color = c.hover_color,
        .check_color = c.check_color,
        .on_toggle = c.on_toggle,
    };
}

pub fn toDrawable(self: *CheckBox) modules.Drawable {
    return modules.Drawable{
        .dim = self.dim,
        .color = self.box_color,
        .drawStrategy = &self._draw_strategy,
    };
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
        sdl.c.SDL_Log("CheckBox: unable to render geometry: %s", sdl.c.SDL_GetError());
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
    const self = @as(*CheckBox, @constCast(@fieldParentPtr("_draw_strategy", ds)));

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
                self.checked = !self.checked;
                if (self.on_toggle) |cb| cb(self);
            }
            self._state = .Hover;
        }
    } else {
        self._state = .Idle;
    }
    self._prev_mouse_down = mouse_down and inside;

    const fill = switch (self._state) {
        .Idle => self.box_color,
        .Hover, .Pressed => self.hover_color,
    };

    try fillRect(renderer, pos.x, pos.y, dim.w, dim.h, fill);

    if (self.checked) {
        _ = sdl.c.SDL_SetRenderDrawColor(
            renderer,
            self.check_color.r,
            self.check_color.g,
            self.check_color.b,
            self.check_color.a,
        );
        const a = sdl.c.SDL_FPoint{ .x = pos.x + dim.w * 0.22, .y = pos.y + dim.h * 0.55 };
        const b = sdl.c.SDL_FPoint{ .x = pos.x + dim.w * 0.45, .y = pos.y + dim.h * 0.80 };
        const c = sdl.c.SDL_FPoint{ .x = pos.x + dim.w * 0.80, .y = pos.y + dim.h * 0.28 };
        if (!sdl.c.SDL_RenderLine(renderer, a.x, a.y, b.x, b.y)) {
            return error.RenderFailed;
        }
        if (!sdl.c.SDL_RenderLine(renderer, b.x, b.y, c.x, c.y)) {
            return error.RenderFailed;
        }
    }
}

fn destroy(_: *modules.Drawable, _: *const modules.DrawStrategy) void {}

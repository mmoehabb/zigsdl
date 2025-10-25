const std = @import("std");
const sdl = @import("../sdl.zig");
const types = @import("../types/mod.zig");

pub const DrawStrategy = struct {
    draw: *const fn (
        _: *Drawable,
        _: *const DrawStrategy,
        _: *sdl.c.SDL_Renderer,
        _: types.common.Position,
        _: types.common.Rotation,
        _: types.common.Dimensions,
    ) error{RenderFailed}!void,

    destroy: *const fn (_: *Drawable, _: *const DrawStrategy) void,
};

pub const Drawable = struct {
    dim: types.common.Dimensions,
    drawStrategy: *const DrawStrategy,
    color: ?types.common.Color,

    pub fn draw(
        self: *Drawable,
        renderer: *sdl.c.SDL_Renderer,
        pos: types.common.Position,
        rot: types.common.Rotation,
    ) !void {
        if (self.color) |color| _ = sdl.c.SDL_SetRenderDrawColor(renderer, color.r, color.g, color.b, color.a);
        try self.drawStrategy.draw(self, self.drawStrategy, renderer, pos, rot, self.dim);
    }

    pub fn destroy(self: *Drawable) void {
        self.drawStrategy.destroy(self, self.drawStrategy);
    }

    pub fn setDim(self: *Drawable, newdim: types.common.Dimensions) void {
        self.dim = newdim;
    }
};

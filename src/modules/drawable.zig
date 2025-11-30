//! This module contains structs to define and implement drawables.

const std = @import("std");
const sdl = @import("../sdl.zig");
const types = @import("../types/mod.zig");

/// This component is the key to customize/extend the behavior of drawables.
/// It shall only be used when defining a new drawable.
///
/// For example:
///
/// ```zig
/// pub const Rect = struct {
///    dim: types.Dimensions,
///    color: types.Color = .{},
///    _draw_strategy: modules.DrawStrategy = modules.DrawStrategy{
///        .draw = draw,
///        .destroy = destroy,
///    },
///    ...
///    pub fn toDrawable(self: *Rect) modules.Drawable {
///        return modules.Drawable{
///            .dim = self.dim,
///            .color = self.color,
///            .drawStrategy = &self._draw_strategy,
///        };
///    }
///    ...
/// }
/// ```
pub const DrawStrategy = struct {
    draw: *const fn (
        _: *Drawable,
        _: *const DrawStrategy,
        _: *sdl.c.SDL_Renderer,
        _: types.Position,
        _: types.Rotation,
        _: types.Dimensions,
    ) error{RenderFailed}!void,

    destroy: *const fn (_: *Drawable, _: *const DrawStrategy) void,
};

/// An abstract struct, or _abstract drawable_, that shall be used to represent
/// [concrete drawables](#root.drawables) in the way that [objects](#root.modules.object) understand.
///
/// For example:
/// ```zig
/// const MyDefinedDrawable = struct {
///     ...
///     pub fn toDrawable(self: *MyDefinedDrawable) Drawable {...}
///     ...
/// };
///
/// const myObj = Object{
///     .drawable = MyDefinedDrawable{}.toDrawable(),
/// }
/// ```
pub const Drawable = struct {
    /// The dimensions of the drawable.
    dim: types.Dimensions,

    /// The draw and destroy functionality are extended through this struct.
    drawStrategy: *const DrawStrategy,

    /// The color to be set before drawing.
    color: ?types.Color,

    /// This should only be called by [the object component](#root.modules.object.Object).
    pub fn draw(
        self: *Drawable,
        renderer: *sdl.c.SDL_Renderer,
        pos: types.Position,
        rot: types.Rotation,
    ) !void {
        if (self.color) |color| _ = sdl.c.SDL_SetRenderDrawColor(renderer, color.r, color.g, color.b, color.a);
        try self.drawStrategy.draw(self, self.drawStrategy, renderer, pos, rot, self.dim.getScaled());
    }

    /// This should only be called by the _object_ component.
    pub fn destroy(self: *Drawable) void {
        self.drawStrategy.destroy(self, self.drawStrategy);
    }

    /// This should only be needed while implementing a custom drawable.
    ///
    /// It has been proven to be usful while implementing
    /// the [text drawable](#root.drawables.text.Text); whereas the dimensions
    /// of the drawable (text) is actually evaluated after drawing it.
    pub fn setDim(self: *Drawable, newdim: types.Dimensions) void {
        self.dim = newdim;
    }
};

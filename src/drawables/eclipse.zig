//! A concrete drawable to render a simple eclipse by using SDL_RenderGeometry.

const std = @import("std");
const sdl = @import("../sdl.zig");
const modules = @import("../modules/mod.zig");
const types = @import("../types/mod.zig");
const SVG = @import("./svg.zig");

const Eclipse = @This();

dim: types.Dimensions,
color: types.Color = .{},

// NOTE: dimention width is considered radius 1 (doubled), and the height for radius 2.
pub fn new(io: std.Io, dim: types.Dimensions, _: types.Color) SVG {
    const svg_str =
        \\ <svg width="50" height="50">
        \\   <circle cx="25" cy="25" r="25" stroke="black" stroke-width="3" fill="red" />
        \\ </svg>
    ;
    return SVG.new(SVG{
        .io = io,
        .content = svg_str,
        .dim = dim,
    });
}

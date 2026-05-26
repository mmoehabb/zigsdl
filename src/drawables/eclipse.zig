//! A concrete drawable to render a simple eclipse by using the power of SVG.
//! NOTE: this is a simple wrapper on the SVG component.

const std = @import("std");
const sdl = @import("../sdl.zig");
const modules = @import("../modules/mod.zig");
const types = @import("../types/mod.zig");
const SVG = @import("./svg.zig");

const Ellipse = @This();

dim: types.Dimensions,
color: types.Color = .{},

// NOTE: dimention width is considered radius 1 (doubled), and the height for radius 2.
pub fn new(io: std.Io, dim: types.Dimensions, _: types.Color) !SVG {
    const format =
        \\<svg width="{0}" height="{1}" xmlns="http://www.w3.org/2000/svg">
        \\<ellipse cx="{2}" cy="{3}" rx="{2}" ry="{3}" fill="red" />
        \\</svg>
    ;

    // TODO: improve error handling here
    var str = try modules.Globals.stringFactory.?.createBuffer(512);

    const svg_content = std.fmt.bufPrint(
        str.getBuffer(),
        format,
        .{
            dim.w * 2,
            dim.h * 2,
            dim.w,
            dim.h,
        },
    ) catch "<svg></svg>";

    return SVG.new(SVG{
        .io = io,
        .content = svg_content,
        .dim = dim,
    });
}

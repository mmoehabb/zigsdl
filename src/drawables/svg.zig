//! A concrete drawable to render a simple rectangle by using SDL_RenderGeometry.

const std = @import("std");
const sdl = @import("../sdl.zig");
const modules = @import("../modules/mod.zig");
const types = @import("../types/mod.zig");

const SVG = @This();

/// The path of the svg file
path: []const u8 = "",

/// SVG file content, this can be used instead of passing a path of a simple svg file
content: []const u8 = "",

dim: types.Dimensions = .{},

/// Used in creating a temporary file, in case the content is provided.
io: std.Io,

_texture: [*c]sdl.c.SDL_Texture = null,
_draw_strategy: modules.DrawStrategy = modules.DrawStrategy{
    .draw = draw,
    .destroy = destroy,
},

pub fn new(svg: SVG) SVG {
    return SVG{
        .io = svg.io,
        .path = svg.path,
        .content = svg.content,
        .dim = svg.dim,
    };
}

pub fn toDrawable(self: *SVG) modules.Drawable {
    return modules.Drawable{
        .dim = self.dim,
        .color = .{},
        .drawStrategy = &self._draw_strategy,
    };
}

pub fn getDim(self: *SVG) types.Dimensions {
    return .{
        .w = if (self._texture) |t| @floatFromInt(t.*.w) else 0,
        .h = if (self._texture) |t| @floatFromInt(t.*.h) else 0,
        .d = 1,
        .scale = self.dim.scale,
    };
}

fn draw(
    drawable: *modules.Drawable,
    ds: *const modules.DrawStrategy,
    renderer: *sdl.c.SDL_Renderer,
    pos: types.Position,
    _: types.Rotation,
    dim: types.Dimensions,
) !void {
    const self = @as(*SVG, @constCast(@fieldParentPtr("_draw_strategy", ds)));

    const texture = self._texture orelse blk: {
        if (self.content.len > 0) {
            // Create a temporary file of the svg content
            const file = std.Io.Dir.createFileAbsolute(self.io, "/tmp/zigsdl.tmp.svg", .{}) catch return error.InvalidInputs;
            defer file.close(self.io);
            file.writeStreamingAll(self.io, self.content) catch unreachable;

            // Store the file path into svg_path variable
            self.path = "/tmp/zigsdl.tmp.svg";

            // Ensure the temp file is being cleaned up
            // NOTE: it's being removed in the destroy method below
        }
        self._texture = sdl.c.IMG_LoadTexture(renderer, self.path.ptr);
        break :blk self._texture;
    };
    // TODO: extend the error type to include more useful values
    if (texture == null) return error.RenderFailed;

    const dest = sdl.c.SDL_FRect{
        .x = pos.x,
        .y = pos.y,
        .w = dim.w,
        .h = dim.h,
    };

    if (!sdl.c.SDL_RenderTexture(renderer, texture, null, &dest)) {
        sdl.c.SDL_Log("Failed to render SVG: %s\n", sdl.c.SDL_GetError());
        return error.RenderFailed;
    }

    drawable.setDim(.{
        .w = @as(f32, @floatFromInt(texture.*.w)),
        .h = @as(f32, @floatFromInt(texture.*.h)),
        .d = 1,
        .scale = self.dim.scale,
    });
}

fn destroy(_: *modules.Drawable, ds: *const modules.DrawStrategy) void {
    const self = @as(*SVG, @constCast(@fieldParentPtr("_draw_strategy", ds)));
    if (self._texture) |_| sdl.c.SDL_DestroyTexture(self._texture.?);
    if (self.content.len > 0) std.Io.Dir.deleteFileAbsolute(self.io, self.path) catch {};
}

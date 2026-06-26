const zigsdl = @import("zigsdl");
const std = @import("std");

pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;

    try zigsdl.modules.Globals.init(allocator, init.io);
    defer zigsdl.modules.Globals.deinit();

    // Create a drawable object
    var rect = zigsdl.drawables.Rect.new(
        .{ .w = 20, .h = 20, .d = 1 },
        .{ .r = 255 },
    );
    var rect_drawable = rect.toDrawable();

    var box = zigsdl.modules.Object.init(allocator, .{
        .name = "Box",
        .position = .{ .x = 20, .y = 20, .z = 1 },
        .rotation = .{ .x = 0, .y = 0, .z = 0 },
        .drawable = &rect_drawable,
    });
    defer box.deinit();

    // Add scripts to the object
    var points = [_]zigsdl.types.Position{.{}};
    var mesh = zigsdl.scripts.Mesh{ .points = &points };
    var rigidbody = zigsdl.scripts.Rigidbody{ .mass = 5, .gravity = true };
    try box.addScript(@constCast(&mesh.toScript()));
    try box.addScript(@constCast(&rigidbody.toScript()));

    var terrain_rect = zigsdl.drawables.Rect.new(
        .{ .w = 250, .h = 50, .d = 1 },
        .{ .g = 255 },
    );
    var terrain_drawable = terrain_rect.toDrawable();
    var terrain = zigsdl.modules.Object.init(allocator, .{
        .name = "Terrain",
        .position = .{ .x = 0, .y = 250, .z = 0 },
        .rotation = .{ .x = 0, .y = 0, .z = 0 },
        .drawable = &terrain_drawable,
    });
    defer terrain.deinit();

    // Create a scene and add the obj into it
    var scene = zigsdl.modules.Scene.init(allocator);
    defer scene.deinit();
    try scene.addObject(&box);
    try scene.addObject(&terrain);

    // Create a screen, attach the scene to it, and open it
    var screen = try zigsdl.modules.Screen.init(.{
        .title = "Simple Game",
        .width = 320,
        .height = 320,
        .rate = 1000 / 60,
    });
    defer screen.deinit();
    screen.setScene(&scene);
    try screen.open();
}

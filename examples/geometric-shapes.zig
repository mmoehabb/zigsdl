const zigsdl = @import("zigsdl");
const std = @import("std");

pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;

    // A Green Rectangle
    var rect = zigsdl.drawables.Rect.new(
        .{ .w = 50, .h = 25, .d = 1 },
        .{ .g = 255 },
    );
    var rect_drawable = rect.toDrawable();

    var obj1 = zigsdl.modules.Object.init(allocator, .{
        .name = "GreenRect",
        .position = .{ .x = 20, .y = 20, .z = 1 },
        .rotation = .{ .x = 0, .y = 0, .z = 0 },
        .drawable = &rect_drawable,
    });
    defer obj1.deinit();

    // A Red Square
    var square = zigsdl.drawables.Rect.new(
        .{ .w = 50, .h = 50, .d = 1 },
        .{ .r = 255 },
    );
    var square_drawable = square.toDrawable();
    var obj2 = zigsdl.modules.Object.init(allocator, .{
        .name = "RedSquare",
        .position = .{ .x = 20, .y = 65, .z = 1 },
        .rotation = .{ .x = 0, .y = 0, .z = 0 },
        .drawable = &square_drawable,
    });
    defer obj2.deinit();

    // Add Blue Circle
    var circle = zigsdl.drawables.Eclipse.new(
        init.io,
        .{ .w = 25, .h = 25, .d = 1 },
        .{ .b = 255 },
    );
    var circle_drawable = circle.toDrawable();
    var obj3 = zigsdl.modules.Object.init(allocator, .{
        .name = "BlueCircle",
        .position = .{ .x = 20, .y = 135, .z = 1 },
        .rotation = .{ .x = 0, .y = 0, .z = 0 },
        .drawable = &circle_drawable,
    });
    defer obj3.deinit();

    // Add Yellow Triangle
    var triangle = zigsdl.drawables.Triangle.new(
        .{ .w = 50, .h = 50, .d = 1 },
        .{ .r = 255, .g = 255 },
    );
    var triangle_drawable = triangle.toDrawable();
    var obj4 = zigsdl.modules.Object.init(allocator, .{
        .name = "YellowTriangle",
        .position = .{ .x = 20, .y = 205, .z = 1 },
        .rotation = .{ .x = 0, .y = 0, .z = 0 },
        .drawable = &triangle_drawable,
    });
    defer obj4.deinit();

    // Create a scene and add the obj into it
    var scene = zigsdl.modules.Scene.init(allocator);
    defer scene.deinit();

    try scene.addObject(&obj1);
    try scene.addObject(&obj2);
    try scene.addObject(&obj3);
    try scene.addObject(&obj4);

    // Create a screen, attach the scene to it, and open it
    var screen = try zigsdl.modules.Screen.init(allocator, .{
        .title = "Simple Game",
        .width = 320,
        .height = 320,
        .rate = 1000 / 60,
    });
    defer screen.deinit();
    screen.setScene(&scene);
    try screen.open();
}

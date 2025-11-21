const zigsdl = @import("zigsdl");
const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer {
        const deinit_status = gpa.deinit();
        if (deinit_status == .leak) std.debug.panic("Memory leak detected!", .{});
    }

    // Create a drawable object
    var rect = zigsdl.drawables.Rect.new(
        .{ .w = 20, .h = 20, .d = 1 },
        .{ .g = 255 },
    );
    var rect_drawable = rect.toDrawable();

    var obj = zigsdl.modules.Object.init(.{
        .allocator = allocator,
        .name = "GreenBox",
        .position = .{ .x = 20, .y = 20, .z = 1 },
        .rotation = .{ .x = 0, .y = 0, .z = 0 },
        .drawable = &rect_drawable,
    });

    // Add movement script to the object
    var movement = zigsdl.scripts.Movement{ .velocity = 5, .smooth = true };
    try obj.addScript(@constCast(&movement.toScript()));

    // Add a child object to obj
    var rect2 = zigsdl.drawables.Rect.new(
        .{ .w = 10, .h = 10, .d = 1 },
        .{ .r = 255 },
    );
    var rect2_drawable = rect2.toDrawable();
    var obj2 = zigsdl.modules.Object.init(.{
        .allocator = allocator,
        .name = "RedBox",
        .position = .{ .x = 5, .y = 5, .z = 0 },
        .rotation = .{ .x = 0, .y = 0, .z = 0 },
        .drawable = &rect2_drawable,
    });
    try obj.addChild(&obj2);

    // Create a scene and add the obj into it
    var scene = zigsdl.modules.Scene.init(allocator);
    try scene.addObject(&obj);

    // Create a screen, attach the scene to it, and open it
    var screen = zigsdl.modules.Screen.init(.{
        .allocator = allocator,
        .title = "Simple Game",
        .width = 320,
        .height = 320,
        .rate = 1000 / 60,
    });
    defer screen.deinit();
    screen.setScene(&scene);
    try screen.open();
}

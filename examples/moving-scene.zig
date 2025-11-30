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
        .{ .w = 550, .h = 70, .d = 1 },
        .{ .g = 255 },
    );
    var rect_drawable = rect.toDrawable();

    var obj = zigsdl.modules.Object.init(allocator, .{
        .name = "Ground",
        .position = .{ .x = -100, .y = 250, .z = 1 },
        .rotation = .{ .x = 0, .y = 0, .z = 0 },
        .drawable = &rect_drawable,
    });
    defer obj.deinit();

    // Add a child object to obj
    var rect2 = zigsdl.drawables.Rect.new(
        .{ .w = 60, .h = 100, .d = 1 },
        .{ .r = 255 },
    );
    var rect2_drawable = rect2.toDrawable();
    var obj2 = zigsdl.modules.Object.init(allocator, .{
        .name = "RedBar",
        .position = .{ .x = 50, .y = 150, .z = 1 },
        .rotation = .{ .x = 0, .y = 0, .z = 0 },
        .drawable = &rect2_drawable,
    });
    defer obj2.deinit();

    // Add a child object to obj
    var rect3 = zigsdl.drawables.Rect.new(
        .{ .w = 60, .h = 100, .d = 1 },
        .{ .b = 255 },
    );
    var rect3_drawable = rect3.toDrawable();
    var obj3 = zigsdl.modules.Object.init(allocator, .{
        .name = "BlueBar",
        .position = .{ .x = 150, .y = 100, .z = 1 },
        .rotation = .{ .z = -45 },
        .drawable = &rect3_drawable,
    });
    defer obj3.deinit();

    // Create a scene and add the obj into it
    var scene = zigsdl.modules.Scene.init(allocator);
    defer scene.deinit();
    try scene.addObject(&obj);
    try scene.addObject(&obj2);
    try scene.addObject(&obj3);

    scene.lifecycle.postUpdate = struct {
        fn func(self: *anyopaque) void {
            const s = @as(*zigsdl.modules.Scene, @ptrCast(@alignCast(self)));
            if (s.screen.?._em.isKeyDown(.W)) s.move(.{ .y = 5 });
            if (s.screen.?._em.isKeyDown(.D)) s.move(.{ .x = -5 });
            if (s.screen.?._em.isKeyDown(.S)) s.move(.{ .y = -5 });
            if (s.screen.?._em.isKeyDown(.A)) s.move(.{ .x = 5 });
            if (s.screen.?._em.isKeyDown(.E)) s.scale += 0.1;
            if (s.screen.?._em.isKeyDown(.Q)) s.scale -= 0.1;
        }
    }.func;

    // Create a screen, attach the scene to it, and open it
    var screen = zigsdl.modules.Screen.init(allocator, .{
        .title = "Simple Game",
        .width = 320,
        .height = 320,
        .rate = 1000 / 60,
    });
    defer screen.deinit();
    screen.setScene(&scene);
    try screen.open();
}

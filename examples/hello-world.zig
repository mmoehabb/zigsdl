const zigsdl = @import("zigsdl");
const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer {
        const deinit_status = gpa.deinit();
        if (deinit_status == .leak) std.debug.panic("Memory leak detected!", .{});
    }

    const screen_width = 320;
    const screen_height = 320;

    // Create a drawable object
    var text = zigsdl.drawables.Text.new(.{
        .text = "Hello World!",
        .font_path = "./examples/assets/OpenSans-Regular.ttf",
        .font_size = 24,
    });
    var text_drawable = text.toDrawable();

    var obj = zigsdl.modules.Object.init(.{
        .allocator = allocator,
        .position = .{ .x = 20, .y = 20, .z = 1 },
        .rotation = .{ .x = 0, .y = 0, .z = 0 },
        .drawable = &text_drawable,
    });
    defer obj.deinit();

    // Center the drawable object in the screen
    obj.lifecycle.postUpdate = struct {
        fn func(self: *anyopaque) void {
            const o = @as(*zigsdl.modules.Object, @ptrCast(@alignCast(self)));
            const dim = o.drawable.?.dim;
            o.position.x = (screen_width - dim.w) / 2;
            o.position.y = (screen_height - dim.h) / 2;
        }
    }.func;

    // Create a scene and add the obj into it
    var scene = zigsdl.modules.Scene.init(allocator);
    defer scene.deinit();
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

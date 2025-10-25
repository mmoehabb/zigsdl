const zigsdl = @import("zigsdl");
const std = @import("std");

pub fn main() !void {
    const screen_width = 320;
    const screen_height = 320;

    // create a drawable object
    var text = zigsdl.drawables.Text.new(.{
        .text = "Hello World!",
        .font_path = "./examples/assets/OpenSans-Regular.ttf",
        .font_size = 24,
    });
    var text_drawable = text.toDrawable();

    var obj = zigsdl.modules.Object{
        .position = .{ .x = 20, .y = 20, .z = 1 },
        .rotation = .{ .x = 0, .y = 0, .z = 0 },
        .drawable = &text_drawable,
    };

    // center the drawable object in the screen
    obj.lifecycle.postUpdate = struct {
        fn func(self: *anyopaque) void {
            const o = @as(*zigsdl.modules.Object, @ptrCast(@alignCast(self)));
            const dim = o.drawable.?.dim;
            o.position.x = (screen_width - dim.w) / 2;
            o.position.y = (screen_height - dim.h) / 2;
        }
    }.func;

    // create a scene and add the obj into it
    var scene = zigsdl.modules.Scene.new();
    try scene.addObject(&obj);

    // create a screen, attach the scene to it, and open it
    var screen = zigsdl.modules.Screen.new(
        "Simple Game",
        screen_width,
        screen_height,
        1000 / 60,
    );
    screen.setScene(&scene);
    try screen.open();
}

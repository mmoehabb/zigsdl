const zigsdl = @import("zigsdl");
const std = @import("std");

pub fn main() !void {
    // create a drawable object
    var text = zigsdl.drawables.Text.new(.{
        .text = "Hello World!",
        .font_path = "./examples/assets/OpenSans-Regular.ttf",
        .font_size = 24,
    });

    var obj = zigsdl.modules.Object{
        .position = .{ .x = 20, .y = 20, .z = 1 },
        .rotation = .{ .x = 0, .y = 0, .z = 0 },
        .drawable = &text.toDrawable(),
    };

    // create a scene and add the obj into it
    var scene = zigsdl.modules.Scene.new();
    try scene.addObject(&obj);

    // create a screen, attach the scene to it, and open it
    var screen = zigsdl.modules.Screen.new(
        "Simple Game",
        320,
        320,
        1000 / 60,
        &zigsdl.types.common.LifeCycle{
            .preOpen = null,
            .postOpen = null,
            .preUpdate = null,
            .postUpdate = null,
            .preClose = null,
            .postClose = null,
        },
    );
    screen.setScene(&scene);
    try screen.open();
}

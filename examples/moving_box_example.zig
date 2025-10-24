const zigsdl = @import("zigsdl");

pub fn main() !void {
    // create a drawable object
    var rect = zigsdl.drawables.Rect.new(.{ .w = 20, .h = 20, .d = 1 }, .{ .g = 255 });

    var obj = zigsdl.modules.Object{
        .position = .{ .x = 20, .y = 20, .z = 1 },
        .rotation = .{ .x = 0, .y = 0, .z = 0 },
        .drawable = &rect.toDrawable(),
    };

    // add movement script to the object
    try obj.addScript(zigsdl.scripts.Movement.new(5, true));

    // add child objects to obj
    var rect2 = zigsdl.drawables.Rect.new(.{ .w = 10, .h = 10, .d = 1 }, .{ .r = 255 });
    var obj2 = zigsdl.modules.Object{
        .position = .{ .x = 5, .y = 5, .z = 0 },
        .rotation = .{ .x = 0, .y = 0, .z = 0 },
        .drawable = &rect2.toDrawable(),
    };
    try obj.addChild(&obj2);

    // create a scene and add the obj into it
    var scene = zigsdl.modules.Scene.new();
    try scene.addObject(&obj);

    // create a screen, attach the scene to it, and open it
    var screen = zigsdl.modules.Screen.new(
        "Simple Game",
        320,
        320,
        1000 / 60,
    );
    screen.setScene(&scene);
    try screen.open();
}

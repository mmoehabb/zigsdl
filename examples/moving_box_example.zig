const zigsdl = @import("zigsdl");

pub fn main() !void {
    // create a drawable object
    const rect = zigsdl.drawables.Rect.new(.{ .w = 20, .h = 20, .d = 1 }, .{ .g = 255 });
    var obj = zigsdl.modules.Object{
        .position = .{ .x = 20, .y = 20, .z = 1 },
        .rotation = .{ .x = 0, .y = 0, .z = 0 },
        .drawable = &rect,
        .scene = undefined,
    };

    // add movement script to the object
    try obj.addScript(zigsdl.scripts.Movement.new(5, true));

    // create a scene and add the drawable obj into it
    var scene = zigsdl.modules.Scene.new();
    try scene.addObject(&obj);

    // create a screen, attach the scene to it, and open it
    var screen = zigsdl.modules.Screen.new("Simple Game", 320, 320, 1000 / 60, &zigsdl.types.common.LifeCycle{
        .preOpen = null,
        .postOpen = null,
        .preUpdate = null,
        .postUpdate = null,
        .preClose = null,
        .postClose = null,
    });
    screen.setScene(&scene);
    try screen.open();
}

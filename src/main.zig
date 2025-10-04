const modules = @import("./modules/mod.zig");
const types = @import("./types/mod.zig");

const Rect = @import("./drawables/rect.zig");
const Movement = @import("./scripts/movement.zig").Movement;

pub fn main() !void {
    // create a drawable object
    const rect = Rect.new(.{ .w = 20, .h = 20, .d = 1 }, .{ .g = 255 });
    var obj = modules.Object{
        .position = .{ .x = 20, .y = 20, .z = 1 },
        .rotation = .{ .x = 0, .y = 0, .z = 0 },
        .drawable = &rect,
        .scene = undefined,
    };

    // add movement script to the object
    try obj.addScript(Movement.new(5));

    // create a scene and add the drawable obj into it
    var scene = modules.Scene.new();
    try scene.addObject(&obj);

    // create a screen, attach the scene to it, and open it
    var screen = modules.Screen.new("Simple Game", 320, 320, 10, &types.common.LifeCycle{
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

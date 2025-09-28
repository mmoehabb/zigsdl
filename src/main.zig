const Screen = @import("./modules/screen.zig").Screen;
const LifeCycle = @import("./types/common.zig").LifeCycle;

const Scene = @import("./modules/scene.zig").Scene;
const Object = @import("./modules/object.zig").Object;
const Rect = @import("./drawables/rect.zig");

pub fn main() !void {
    var screen = Screen.new("Simple Game", 320, 320, &LifeCycle{
        .preOpen = null,
        .postOpen = null,
        .preUpdate = null,
        .postUpdate = null,
        .preClose = null,
        .postClose = null,
    });

    const rect = Rect.new(.{ .w = 20, .h = 20, .d = 1 }, .{ .g = 255 });
    var obj = Object{
        .position = .{ .x = 20, .y = 20, .z = 1 },
        .rotation = .{ .x = 0, .y = 0, .z = 0 },
        .drawable = &rect,
    };

    var scene = Scene.new();
    try scene.addObject(&obj);

    screen.setScene(&scene);
    try screen.open();
}

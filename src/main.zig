const Screen = @import("./modules/screen.zig").Screen;
const LifeCycle = @import("./types/common.zig").LifeCycle;

const Scene = @import("./modules/scene.zig").Scene;
const Object = @import("./modules/object.zig").Object;
const Drawable = @import("./modules/drawable.zig").Drawable;

pub fn main() !void {
    var screen = Screen.new("Simple Game", 320, 320, &LifeCycle{
        .preOpen = null,
        .postOpen = null,
        .preUpdate = null,
        .postUpdate = null,
        .preClose = null,
        .postClose = null,
    });

    var obj = Object{
        .position = .{ .x = 20, .y = 20, .z = 1 },
        .rotation = .{ .x = 0, .y = 0, .z = 0 },
        .drawable = &Drawable{ .width = 20, .height = 20, .color = .{ .g = 255 } },
    };

    var scene = Scene.new();
    try scene.addObject(&obj);

    screen.setScene(&scene);
    try screen.open();
}

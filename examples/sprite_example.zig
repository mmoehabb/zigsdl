const zigsdl = @import("zigsdl");

pub fn main() !void {
    // create a drawable object
    var sprite = zigsdl.drawables.Sprite.new(.{
        .img_path = "./examples/assets/anim_explosion.png",
        .frames_count = 7,
        .frame_width = 128,
        .frame_height = 140,
    });
    var sprite_drawable = sprite.toDrawable(
        .{ .w = 120, .h = 150, .d = 1 },
        .{},
    );

    var obj = zigsdl.modules.Object.new(.{
        .position = .{ .x = 20, .y = 20, .z = 1 },
        .rotation = .{ .x = 0, .y = 0, .z = 0 },
        .drawable = &sprite_drawable,
    });

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

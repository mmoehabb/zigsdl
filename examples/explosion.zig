const zigsdl = @import("zigsdl");

pub fn main() !void {
    // Create sprite object
    var idle = zigsdl.drawables.Sprite.new(.{
        .img_path = "./examples/assets/anim_explosion.png",
        .frames_count = 0,
        .frame_width = 128,
        .frame_height = 140,
    });
    var idle_drawable = idle.toDrawable(
        .{ .w = 120, .h = 150, .d = 1 },
        .{},
    );

    var obj = zigsdl.modules.Object.new(.{
        .position = .{ .x = 100, .y = 20, .z = 1 },
        .rotation = .{ .x = 0, .y = 0, .z = 0 },
        .drawable = &idle_drawable,
    });

    // Create text object
    var text = zigsdl.drawables.Text.new(.{
        .text = "Press Space",
        .font_path = "./examples/assets/OpenSans-Regular.ttf",
        .font_size = 24,
    });
    var text_drawable = text.toDrawable();

    var obj2 = zigsdl.modules.Object.new(.{
        .position = .{ .x = 90, .y = 170, .z = 1 },
        .rotation = .{ .x = 0, .y = 0, .z = 0 },
        .drawable = &text_drawable,
    });

    // Add audioPlayer script to obj
    var audioPlayer = zigsdl.scripts.AudioPlayer{
        .wav_path = "./examples/assets/explosion.wav",
    };
    try obj.addScript(@constCast(&audioPlayer.toScript()));

    // Extend the update function in the obj so that
    // the drawable changes to explode and the audio plays
    // once the user presses space
    obj.lifecycle.postUpdate = struct {
        var explode = zigsdl.drawables.Sprite.new(.{
            .img_path = "./examples/assets/anim_explosion.png",
            .frames_count = 7,
            .frame_width = 128,
            .frame_height = 140,
        });
        var explode_drawable = explode.toDrawable(
            .{ .w = 120, .h = 150, .d = 1 },
            .{},
        );

        var pressed = false;

        fn func(self: *anyopaque) void {
            const o = @as(*zigsdl.modules.Object, @ptrCast(@alignCast(self)));
            var em = o.*._scene.?.screen.?.em;

            if (em.isKeyDown(.Space) and !pressed) {
                if (o.getScript(zigsdl.scripts.AudioPlayer, "AudioPlayer")) |ap| ap.play();
                o.setDrawable(&explode_drawable);
                pressed = true;
            }
        }
    }.func;

    // Create a scene and add the obj into it
    var scene = zigsdl.modules.Scene.new();
    try scene.addObject(&obj);
    try scene.addObject(&obj2);

    // Create a screen, attach the scene to it, and open it
    var screen = zigsdl.modules.Screen.new(
        "Simple Game",
        320,
        320,
        1000 / 60,
    );
    screen.setScene(&scene);
    try screen.open();
}

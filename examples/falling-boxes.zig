const zest = @import("zest");
const std = @import("std");

pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;

    // Initialize the plugin manager
    const pm = zest.modules.PluginManager;
    try pm.init(allocator);
    defer pm.deinit();

    // >>> Define and add plugins
    var collisionDetector = zest.plugins.CollisionDetector.init(allocator, init.io);
    try collisionDetector.start(false);
    defer collisionDetector.deinit();
    try pm.add(&collisionDetector, "CollisionDetector");

    var eventManager = zest.plugins.EventManager.init(allocator);
    defer eventManager.deinit();
    try pm.add(&eventManager, "EventManager");

    var jammingResolver = try zest.plugins.JammingResolver.init(allocator);
    defer jammingResolver.deinit();
    try pm.add(&jammingResolver, "JammingResolver");
    // <<<

    // Create boxes and terrain objects
    var rect = zest.drawables.Rect.new(
        .{ .w = 20, .h = 20, .d = 1 },
        .{ .r = 255 },
    );
    var box_drawable = rect.toDrawable();

    var boxes: [2]?*Box = @splat(null);
    const names: [2][]const u8 = .{ "Box1", "Box2" };

    // const rng_impl: std.Random.IoSource = .{ .io = init.io };
    // const rng = rng_impl.interface();

    for (0..boxes.len) |i| {
        // const rand1 = rng.float(f32);
        // const rand2 = rng.float(f32);
        boxes[i] = try Box.init(
            allocator,
            &box_drawable,
            names[i],
            .{
                // .x = 300.0 * rand1,
                // .y = 200.0 * rand2,
                .x = 150.0,
                .y = 30.0 * (@as(f32, @floatFromInt(i)) * 3.0),
            },
        );
    }

    defer for (&boxes) |*box| if (box.*) |b| b.deinit();

    var terrain_rect = zest.drawables.Rect.new(
        .{ .w = 320, .h = 50, .d = 1 },
        .{ .g = 255 },
    );
    var terrain_drawable = terrain_rect.toDrawable();
    var terrain = zest.modules.Object.init(allocator, .{
        .name = "Terrain",
        .position = .{ .x = 0, .y = 270 },
        .rotation = .{ .x = 0, .y = 0 },
        .drawable = &terrain_drawable,
    });

    var terrain_faces = [_]zest.types.Face{
        .{
            .p1 = .{ .x = 0, .y = 0 },
            .p2 = .{ .x = 320, .y = 0 },
            .p3 = .{ .x = 320, .y = 50 },
            .p4 = .{ .x = 0, .y = 50 },
            .owner = &terrain,
        },
    };
    var terrain_mesh = try zest.scripts.Mesh.init(allocator, &terrain_faces);
    defer terrain_mesh.deinit();

    var terrain_rigidbody = try zest.scripts.Rigidbody.init(.{
        .allocator = allocator,
        .mass = 500,
        .static = true,
    });
    defer terrain_rigidbody.deinit();

    try terrain.addScript(terrain_mesh.toScript());
    try terrain.addScript(terrain_rigidbody.toScript());
    defer terrain.deinit();

    // Create a scene and add the obj into it
    var scene = zest.modules.Scene.init(allocator);
    defer scene.deinit();

    scene.lifecycle.postUpdate = struct {
        var jr: ?*zest.plugins.JammingResolver = null;
        fn func(_: *anyopaque) void {
            jr = jr orelse zest.modules.PluginManager.get(zest.plugins.JammingResolver, "JammingResolver").?;
            jr.?.resolve(true);
        }
    }.func;

    for (boxes) |box| {
        try scene.addObject(box.?.toObject());
    }
    try scene.addObject(&terrain);

    // Create a screen, attach the scene to it, and open it
    var screen = try zest.modules.Screen.init(.{
        .title = "Simple Game",
        .width = 320,
        .height = 320,
        .rate = 1000 / 60,
    });
    defer screen.deinit();
    screen.setScene(&scene);
    try screen.open();
}

const Box = struct {
    _obj: zest.modules.Object,
    _mesh: *zest.scripts.Mesh,
    _rigidbody: *zest.scripts.Rigidbody,
    _allocator: std.mem.Allocator,

    pub fn init(
        allocator: std.mem.Allocator,
        drawable: *zest.modules.Drawable,
        name: []const u8,
        p: zest.types.Vector,
    ) !*Box {
        var box = try allocator.create(Box);
        box._allocator = allocator;

        box._obj = zest.modules.Object.init(allocator, .{
            .name = name,
            .position = p,
            .rotation = .{ .x = 0, .y = 0 },
            .drawable = drawable,
        });

        var box_faces = [_]zest.types.Face{
            .{
                .p1 = .{ .x = 0, .y = 0 },
                .p2 = .{ .x = 20, .y = 0 },
                .p3 = .{ .x = 20, .y = 20 },
                .p4 = .{ .x = 0, .y = 20 },
                .owner = &box._obj,
            },
        };
        var box_mesh = try zest.scripts.Mesh.init(allocator, &box_faces);
        try box._obj.addScript(box_mesh.toScript());
        box._mesh = box_mesh;

        var box_rigidbody = try zest.scripts.Rigidbody.init(.{
            .allocator = allocator,
            .mass = 5,
            .gravity = 1.00,
            .static = false,
        });
        try box._obj.addScript(box_rigidbody.toScript());
        box._rigidbody = box_rigidbody;

        return box;
    }

    pub fn deinit(self: *Box) void {
        self._obj.deinit();
        self._mesh.deinit();
        self._rigidbody.deinit();
        self._allocator.destroy(self);
    }

    pub fn toObject(self: *Box) *zest.modules.Object {
        return &self._obj;
    }
};

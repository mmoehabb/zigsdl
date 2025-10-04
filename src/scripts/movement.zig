const debug = @import("std").debug;
const modules = @import("../modules/mod.zig");

pub const Movement = struct {
    var delta: f32 = 0;
    var obj: ?*modules.Object = undefined;

    pub fn new(speed: f32) modules.Script {
        delta = speed;
        return modules.Script{
            .start = &start,
            .update = &update,
            .end = &end,
        };
    }

    fn start(o: *modules.Object) void {
        obj = o;
        var em = obj.?.scene.?.screen.?.eventManager;
        em.onKeyDown(.W, &moveUp) catch unreachable;
        em.onKeyDown(.S, &moveDown) catch unreachable;
        em.onKeyDown(.D, &moveRight) catch unreachable;
        em.onKeyDown(.A, &moveLeft) catch unreachable;
    }

    fn update(_: *modules.Object) void {}

    fn end(_: *modules.Object) void {}

    fn moveUp() void {
        obj.?.position.y -= delta;
    }
    fn moveDown() void {
        obj.?.position.y += delta;
    }
    fn moveRight() void {
        obj.?.position.x += delta;
    }
    fn moveLeft() void {
        obj.?.position.x -= delta;
    }
};

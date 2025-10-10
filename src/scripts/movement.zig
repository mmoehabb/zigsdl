const debug = @import("std").debug;
const modules = @import("../modules/mod.zig");

pub const Movement = struct {
    var isSmooth: bool = false;
    var delta: f32 = 0;
    var obj: ?*modules.Object = undefined;

    var up: bool = false;
    var down: bool = false;
    var left: bool = false;
    var right: bool = false;

    pub fn new(speed: f32, smooth: ?bool) modules.Script {
        delta = speed;
        isSmooth = smooth orelse false;
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

        em.onKeyUp(.W, &stopUp) catch unreachable;
        em.onKeyUp(.S, &stopDown) catch unreachable;
        em.onKeyUp(.D, &stopRight) catch unreachable;
        em.onKeyUp(.A, &stopLeft) catch unreachable;
    }

    fn update(_: *modules.Object) void {
        if (up) obj.?.position.y -= delta;
        if (down) obj.?.position.y += delta;
        if (right) obj.?.position.x += delta;
        if (left) obj.?.position.x -= delta;
    }

    fn end(_: *modules.Object) void {}

    fn moveUp() void {
        if (isSmooth) {
            up = true;
            return;
        }
        obj.?.position.y -= delta;
    }
    fn moveDown() void {
        if (isSmooth) {
            down = true;
            return;
        }
        obj.?.position.y += delta;
    }
    fn moveRight() void {
        if (isSmooth) {
            right = true;
            return;
        }
        obj.?.position.x += delta;
    }
    fn moveLeft() void {
        if (isSmooth) {
            left = true;
            return;
        }
        obj.?.position.x -= delta;
    }

    fn stopUp() void {
        up = false;
    }
    fn stopDown() void {
        down = false;
    }
    fn stopRight() void {
        right = false;
    }
    fn stopLeft() void {
        left = false;
    }
};

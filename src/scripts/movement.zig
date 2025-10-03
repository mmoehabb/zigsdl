const debug = @import("std").debug;
const Object = @import("../modules/object.zig").Object;
const Script = @import("../modules/script.zig").Script;

pub const Movement = struct {
    var delta: f32 = 0;
    var obj: ?*Object = undefined;

    pub fn new(speed: f32) Script {
        delta = speed;
        return Script{
            .start = start,
            .update = undefined,
            .end = undefined,
        };
    }

    fn start(o: *Object) void {
        obj = o;
        var em = obj.?.scene.?.screen.?.eventManager;
        em.onKeyDown(.W, moveUp) catch unreachable;
        em.onKeyDown(.S, moveDown) catch unreachable;
        em.onKeyDown(.D, moveRight) catch unreachable;
        em.onKeyDown(.A, moveLeft) catch unreachable;
    }

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

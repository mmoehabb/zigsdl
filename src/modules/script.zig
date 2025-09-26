const Object = @import("./object.zig").Object;

pub const Script = struct {
    object: *Object,
    start: ?fn () void,
    update: ?fn () void,
    end: ?fn () void,

    pub fn setObject(self: *Script, obj: Object) void {
        self.object = obj;
    }
};

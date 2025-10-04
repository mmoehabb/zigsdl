const Object = @import("./object.zig").Object;

pub const Script = struct {
    start: *const fn (obj: *Object) void,
    update: *const fn (obj: *Object) void,
    end: *const fn (obj: *Object) void,
};

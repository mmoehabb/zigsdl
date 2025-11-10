const Object = @import("./object.zig").Object;

pub const ScriptStrategy = struct {
    start: *const fn (_: *Script, _: *Object) void,
    update: *const fn (_: *Script, _: *Object) void,
    end: *const fn (_: *Script, _: *Object) void,
};

pub const Script = struct {
    strategy: *ScriptStrategy,

    pub fn start(self: *Script, obj: *Object) void {
        self.strategy.start(self, obj);
    }

    pub fn update(self: *Script, obj: *Object) void {
        self.strategy.update(self, obj);
    }

    pub fn end(self: *Script, obj: *Object) void {
        self.strategy.end(self, obj);
    }
};

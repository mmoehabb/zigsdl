//! The main purpose of this module is to extend [objects](#root.modules.object) functionality,
//! by defining a customizable component that can be plugged into any [object](#root.modules.object).

const Object = @import("./object.zig");

/// This component is the key to customize/extend the behavior of objects with scripts.
/// It shall only be used when defining a new script.
///
/// For example:
///
/// ```zig
/// pub const Movement = struct {
///    speed: u32,
///    _script_strategy: modules.ScriptStrategy = modules.ScriptStrategy{
///        .start = start,
///        .update = update,
///        .end = end,
///    },
///
///    pub fn toScript(self: *Movement) modules.Script {
///        return modules.Script{
///            .name = "Movement",
///            .strategy = &self._script_strategy,
///        };
///    }
///    ...
/// }
/// ```
pub const ScriptStrategy = struct {
    start: *const fn (_: *Script, _: *Object) void,
    update: *const fn (_: *Script, _: *Object) void,
    end: *const fn (_: *Script, _: *Object) void,
};

pub const Script = struct {
    /// A distinct name so that it can be filtered and accessed via the object.
    /// By convention, It should just equal the exact name of the script.
    ///
    /// For example, AudioPlayer script shall, normally, have the name = "AudioPlayer".
    name: []const u8,

    strategy: *ScriptStrategy,

    /// This method shall be invoked within the [object.start](#root.modules.object.start) method.
    pub fn start(self: *Script, obj: *Object) void {
        self.strategy.start(self, obj);
    }

    /// This method shall be invoked within the [object.update](#root.modules.object.update) method.
    pub fn update(self: *Script, obj: *Object) void {
        self.strategy.update(self, obj);
    }

    /// This method shall only be invoked within [object.deactivate](#root.modules.object.deactivate)
    /// and [object.deinit](#root.modules.object.deinit) methods.
    pub fn end(self: *Script, obj: *Object) void {
        self.strategy.end(self, obj);
    }
};

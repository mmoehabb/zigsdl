//! This module contains the core components of zigsdl.

pub const Drawable = @import("drawable.zig").Drawable;
pub const DrawStrategy = @import("drawable.zig").DrawStrategy;

pub const Object = @import("object.zig");
pub const Scene = @import("scene.zig");
pub const Screen = @import("screen.zig");

pub const Script = @import("script.zig").Script;
pub const ScriptStrategy = @import("script.zig").ScriptStrategy;

pub const EventManager = @import("event-manager.zig");

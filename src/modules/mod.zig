//! This module contains the core components of zigsdl.

pub const Drawable = @import("drawable.zig").Drawable;
pub const DrawStrategy = @import("drawable.zig").DrawStrategy;

pub const Object = @import("object.zig");
pub const Scene = @import("scene.zig");
pub const Screen = @import("screen.zig");

pub const Script = @import("script.zig").Script;
pub const ScriptStrategy = @import("script.zig").ScriptStrategy;

pub const AudioStream = @import("audio-stream.zig");

pub const AudioManager = @import("globals/audio-manager.zig");
pub const EventManager = @import("globals/event-manager.zig");
pub const StringFactory = @import("globals/string-factory.zig");
pub const Globals = @import("globals/mod.zig");

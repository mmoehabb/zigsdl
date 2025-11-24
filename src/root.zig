//! A relatively easy-to-pick, simple, and straightforward package
//! that developers can use in order to write graphic applications
//! in [Zig](https://ziglang.org/). Just as the name indicates it's
//! build on [SDL3](https://www.libsdl.org/).

pub const sdl = @import("sdl.zig").c;
pub const types = @import("types/mod.zig");
pub const modules = @import("modules/mod.zig");
pub const drawables = @import("drawables/mod.zig");
pub const scripts = @import("scripts/mod.zig");

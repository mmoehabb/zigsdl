//! All global static variable are stored and used in and from this component.
//! NOTE: Initializing and deinitializing this component shall only occur in the
//! screen component. You NEVER want to call these methods nor mutate the values of
//! these global variables.

const std = @import("std");
const sdl = @import("../sdl.zig");
const StringFactory = @import("./string-factory.zig");
const EventManager = @import("./event-manager.zig");
const AudioManager = @import("./audio-manager.zig");

var stringFactory: ?StringFactory = null;
var eventManager: ?EventManager = null;
var audioManager: ?AudioManager = null;
var activeWindow: ?*sdl.c.SDL_Window = null;

var initialized = false;

pub fn init(allocator: std.mem.Allocator, io: std.Io) !void {
    if (initialized) return;
    initialized = true;
    stringFactory = try StringFactory.init(allocator);
    eventManager = EventManager.init(allocator);
    audioManager = try AudioManager.init(allocator, io);
}

pub fn deinit() void {
    stringFactory.?.deinit();
    eventManager.?.deinit();
    audioManager.?.deinit();
}

pub fn isInitialized() bool {
    return initialized;
}

pub fn setActiveWindow(window: ?*sdl.c.SDL_Window) void {
    activeWindow = window;
}

pub fn getAll() struct {
    stringFactory: *StringFactory,
    eventManager: *EventManager,
    audioManager: *AudioManager,
    activeWindow: ?*sdl.c.SDL_Window,
} {
    return .{
        .stringFactory = &stringFactory.?,
        .eventManager = &eventManager.?,
        .audioManager = &audioManager.?,
        .activeWindow = activeWindow,
    };
}

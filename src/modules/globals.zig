//! All global static variable are stored and used in and from this component.
//! NOTE: Initializing and deinitializing this component shall only occur in the
//! screen component. You NEVER want to call these methods nor mutate the values of
//! these global variables.

const std = @import("std");
const StringFactory = @import("./string-factory.zig");
const EventManager = @import("./event-manager.zig");

pub var stringFactory: ?StringFactory = null;
pub var eventManager: ?EventManager = null;

var initialized = false;

pub fn init(allocator: std.mem.Allocator) !void {
    if (initialized) return;
    initialized = true;
    stringFactory = try StringFactory.init(allocator);
    eventManager = EventManager.init(allocator);
}

pub fn deinit() void {
    stringFactory.?.deinit();
    eventManager.?.deinit();
}

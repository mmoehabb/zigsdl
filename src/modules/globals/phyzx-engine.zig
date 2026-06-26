const std = @import("std");

const Object = @import("../object.zig");

const PhyzxEngine = @This();

_io: std.Io,
_allocator: std.mem.Allocator,
_objects: std.ArrayList(*Object),

pub fn init(allocator: std.mem.Allocator, io: std.Io) PhyzxEngine {
    return PhyzxEngine{
        ._io = io,
        ._allocator = allocator,
        ._objects = .empty,
    };
}

pub fn deinit(self: *PhyzxEngine) void {
    self._objects.deinit(self._allocator);
}

pub fn addObject(self: *PhyzxEngine, obj: *Object) !void {
    try self._objects.append(self._allocator, obj);
}

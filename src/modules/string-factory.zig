const std = @import("std");

const StringFactory = @This();
const PAGE_SIZE = 1024;

/// List of sorted pairs of indexes, each of which represents a (used) spot in the buffer.
/// Sorted in the same manner they are placed in the buffer.
_store: std.ArrayList(*String) = std.ArrayList(*String).empty,

_allocator: std.mem.Allocator,
_buf: []u8,
_pages_count: usize = 1,

pub fn init(allocator: std.mem.Allocator) !StringFactory {
    const buf = try allocator.alloc(u8, PAGE_SIZE);
    return StringFactory{
        ._allocator = allocator,
        ._buf = buf,
    };
}

pub fn deinit(self: *StringFactory) void {
    self._store.deinit(self._allocator);
    self._allocator.free(self._buf);
}

pub fn create(self: *StringFactory, str: []const u8) !String {
    // check if there is an available spot in the buf; if there is not, extend the buffer.
    // Then copy the string into the buffer
    const start = self.findSpot(str.len) orelse try self.extendTheBuffer(str.len);
    @memcpy(self._buf[start..str.len], str);

    // store the copied string info into the store, with preserving the sorting in the store.
    const end = start + str.len;
    var new_str = String.init(String{
        ._factory = self,
        ._start = start,
        ._end = end,
        ._index = self._store.items.len,
    });

    var i: usize = 0;
    var min: usize = self._buf.len;
    for (self._store.items, 0..) |spot, index| {
        if (spot._start < end) continue;
        const diff = spot._start - end;
        if (diff < min) {
            min = diff;
            i = index;
        }
    }
    try self._store.insert(self._allocator, i, &new_str);

    return new_str;
}

pub fn getOrCreate(self: *StringFactory, str: []const u8) !String {
    for (self._store.items) |spot| {
        const spotStr = self._buf[spot.start..spot.end];
        if (std.mem.eql(u8, spotStr, str)) return spotStr;
    }
    return try self.create(str);
}

/// Searches for an available spot for a string with a specific number of characters.
/// - `len`: the length of the required string.
/// @return: the index of the available spot in the buf, if found, otherwise return undefined.
fn findSpot(self: *StringFactory, len: usize) ?usize {
    if (self._store.items.len == 0 and len <= PAGE_SIZE) return 0;

    var last_end: usize = 0;
    for (self._store.items) |spot| {
        const avai_len = spot._start - last_end;
        if (len <= avai_len) return last_end;
        last_end = spot._end;
    }

    return undefined;
}

/// Extend the current buffer and return the start index of the extent.
/// - `len`: the length of the required string.
/// @return: the index of the start point of the new extent.
fn extendTheBuffer(self: *StringFactory, _: usize) !usize {
    const i = self._buf.len;

    const new_buf = try self._allocator.alloc(u8, i + PAGE_SIZE);
    @memcpy(new_buf[0..i], self._buf);
    self._allocator.free(self._buf);
    self._buf = new_buf;

    return i;
}

/// A spot in the strings type buffer
const String = struct {
    _factory: *StringFactory,
    _start: usize,
    _end: usize,
    _index: usize,

    pub fn init(s: String) String {
        return String{
            ._factory = s._factory,
            ._start = s._start,
            ._end = s._end,
            ._index = s._index,
        };
    }

    pub fn deinit(self: *String) void {
        _ = self._factory._store.orderedRemove(self._index);
    }

    pub fn read(self: *String) []const u8 {
        return self._factory._buf[self._start..self._end];
    }

    pub fn getIndex(self: *String) usize {
        return self._index;
    }
};

// =========================================================
// ===================== Unit Tests ========================
// =========================================================

test "Should successfully create a string" {
    const expect = std.testing.expect;
    const allocator = std.testing.allocator;

    var factory = try StringFactory.init(allocator);
    defer factory.deinit();

    var str = try factory.create("Just Testing");
    try expect(std.mem.eql(u8, "Just Testing", str.read()));
}

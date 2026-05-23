const std = @import("std");

const StringFactory = @This();
const PAGE_SIZE = 1024;

/// List of sorted pairs of indexes, each of which represents a (used) spot in the buffer.
/// Sorted in the same manner they are placed in the buffer.
_store: std.ArrayList(String) = std.ArrayList(String).empty,

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
    @memcpy(self._buf[start .. start + str.len], str);

    // store the copied string info into the store, with preserving the sorting in the store.
    const end = start + str.len;
    const new_str = String{
        .factory = self,
        .start = start,
        .end = end,
    };

    var i: usize = self._store.items.len;
    for (self._store.items, 0..) |spot, index| {
        if (spot.start > start) {
            i = index;
            break;
        }
    }
    try self._store.insert(self._allocator, i, new_str);

    return new_str;
}

pub fn getOrCreate(self: *StringFactory, str: []const u8) !String {
    for (self._store.items) |spot| {
        const spotStr = self._buf[spot.start..spot.end];
        if (std.mem.eql(u8, spotStr, str)) return spot;
    }
    return try self.create(str);
}

/// Searches for an available spot for a string with a specific number of characters.
/// - `len`: the length of the required string.
/// @return: the index of the available spot in the buf, if found, otherwise return null.
fn findSpot(self: *StringFactory, len: usize) ?usize {
    if (self._store.items.len == 0 and len <= PAGE_SIZE) return 0;

    var last_end: usize = 0;
    for (self._store.items) |spot| {
        const avai_len = spot.start - last_end;
        if (len <= avai_len) return last_end;
        last_end = spot.end;
    }

    return null;
}

/// Extend the current buffer and return the start index of the extent.
/// - `len`: the length of the required string.
/// @return: the index of the start point of the new extent.
fn extendTheBuffer(self: *StringFactory, len: usize) !usize {
    const i = self._buf.len;
    const extend_by = @max(PAGE_SIZE, len);

    const new_buf = try self._allocator.alloc(u8, i + extend_by);
    @memcpy(new_buf[0..i], self._buf);
    self._allocator.free(self._buf);
    self._buf = new_buf;

    return i;
}

/// A spot in the strings type buffer
const String = struct {
    factory: *StringFactory,
    start: usize,
    end: usize,

    pub fn read(self: *const String) []const u8 {
        return self.factory._buf[self.start..self.end];
    }

    pub fn destroy(self: *String) void {
        for (self.factory._store.items, 0..) |item, i| {
            if (item.start == self.start and item.end == self.end) {
                _ = self.factory._store.orderedRemove(i);
                break;
            }
        }
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

    const str = try factory.create("Just Testing");
    try expect(std.mem.eql(u8, "Just Testing", str.read()));
}

test "Should create and read multiple strings" {
    const expect = std.testing.expect;
    const allocator = std.testing.allocator;

    var factory = try StringFactory.init(allocator);
    defer factory.deinit();

    const a = try factory.create("Hello");
    const b = try factory.create("World");
    const c = try factory.create("Zig");

    try expect(std.mem.eql(u8, "Hello", a.read()));
    try expect(std.mem.eql(u8, "World", b.read()));
    try expect(std.mem.eql(u8, "Zig", c.read()));
}

test "Should extend buffer when string exceeds PAGE_SIZE" {
    const expect = std.testing.expect;
    const allocator = std.testing.allocator;

    var factory = try StringFactory.init(allocator);
    defer factory.deinit();

    const large = try factory.create("A" ** 1500);
    try expect(std.mem.eql(u8, "A" ** 1500, large.read()));
}

test "Should extend buffer multiple times" {
    const expect = std.testing.expect;
    const allocator = std.testing.allocator;

    var factory = try StringFactory.init(allocator);
    defer factory.deinit();

    const a = try factory.create("A" ** 1024);
    const b = try factory.create("B" ** 1024);
    const c = try factory.create("C" ** 1024);

    try expect(std.mem.eql(u8, "A" ** 1024, a.read()));
    try expect(std.mem.eql(u8, "B" ** 1024, b.read()));
    try expect(std.mem.eql(u8, "C" ** 1024, c.read()));
}

test "getOrCreate should return existing string" {
    const expect = std.testing.expect;
    const allocator = std.testing.allocator;

    var factory = try StringFactory.init(allocator);
    defer factory.deinit();

    const a = try factory.getOrCreate("Duplicate");
    const b = try factory.getOrCreate("Duplicate");

    try expect(std.mem.eql(u8, "Duplicate", a.read()));
    try expect(std.mem.eql(u8, "Duplicate", b.read()));
    try expect(factory._store.items.len == 1);
}

test "getOrCreate should create new string when not found" {
    const expect = std.testing.expect;
    const allocator = std.testing.allocator;

    var factory = try StringFactory.init(allocator);
    defer factory.deinit();

    const a = try factory.getOrCreate("First");
    const b = try factory.getOrCreate("Second");

    try expect(std.mem.eql(u8, "First", a.read()));
    try expect(std.mem.eql(u8, "Second", b.read()));
}

test "Should deinit a string and reclaim its buffer space" {
    const expect = std.testing.expect;
    const allocator = std.testing.allocator;

    var factory = try StringFactory.init(allocator);
    defer factory.deinit();

    var a = try factory.create("ToBeRemoved");
    try expect(std.mem.eql(u8, "ToBeRemoved", a.read()));
    a.destroy();
}

test "Should handle empty strings" {
    const expect = std.testing.expect;
    const allocator = std.testing.allocator;

    var factory = try StringFactory.init(allocator);
    defer factory.deinit();

    const str = try factory.create("");
    try expect(std.mem.eql(u8, "", str.read()));
}

test "Should create many small strings" {
    const expect = std.testing.expect;
    const allocator = std.testing.allocator;

    var factory = try StringFactory.init(allocator);
    defer factory.deinit();

    var i: usize = 0;
    const strings = [_][]const u8{ "a", "bb", "ccc", "dddd", "eeeee" };
    var created: [strings.len]String = undefined;

    for (strings) |s| {
        created[i] = try factory.create(s);
        i += 1;
    }

    for (strings, 0..) |s, j| {
        try expect(std.mem.eql(u8, s, created[j].read()));
    }
}

test "Should reuse freed gaps in the buffer" {
    const expect = std.testing.expect;
    const allocator = std.testing.allocator;

    var factory = try StringFactory.init(allocator);
    defer factory.deinit();

    var a = try factory.create("Hello");
    const b = try factory.create("World");

    const b_start = b.start;
    a.destroy();

    const c = try factory.create("Hi");
    try expect(std.mem.eql(u8, "Hi", c.read()));
    try expect(c.start < b_start);
}

test "Should read correct content after multiple operations" {
    const expect = std.testing.expect;
    const allocator = std.testing.allocator;

    var factory = try StringFactory.init(allocator);
    defer factory.deinit();

    const a = try factory.create("Alpha");
    var b = try factory.create("Beta");
    const c = try factory.create("Gamma");

    try expect(std.mem.eql(u8, "Alpha", a.read()));
    try expect(std.mem.eql(u8, "Beta", b.read()));
    try expect(std.mem.eql(u8, "Gamma", c.read()));

    b.destroy();

    const d = try factory.create("Delta");
    try expect(std.mem.eql(u8, "Delta", d.read()));

    try expect(std.mem.eql(u8, "Alpha", a.read()));
    try expect(std.mem.eql(u8, "Gamma", c.read()));
}

const std = @import("std");

const Strings = @This();
const PAGE_SIZE = 1024;

/// List of sorted pairs of indexes, each of which represents a (used) spot in the buffer.
/// Sorted in the same manner they are placed in the buffer.
_store: std.ArrayList(*Spot) = std.ArrayList(*Spot).empty,

_allocator: std.mem.Allocator,
_buf: []u8,
_pages_count: usize = 1,

pub fn init(allocator: std.mem.Allocator) !*Strings {
    const buf = try allocator.alloc(u8, PAGE_SIZE);
    return &Strings{
        ._allocator = allocator,
        ._buf = buf,
    };
}

pub fn deinit(self: *Strings) void {
    for (self._store.items) |item| item.deinit();
    self._store.deinit(self._allocator);
    self._allocator.free(self._buf);
}

pub fn create(self: *Strings, str: []const u8) !Spot {
    // check if there is an available spot in the buf
    var start = findSpot(str.len);

    // copy the string into the buffer if an available spot is found
    // otherwise, extend the buffer then copy the string
    if (start == -1) start = try self.extendTheBuffer(str.len);
    @memcpy(self._buf[start..str.len], str);

    // store the copied string info into the store, with preserving the sorting in the store.
    const end = start + str.len;
    const new_str = Spot.init(Spot{
        ._factory = self,
        ._start = start,
        ._end = end,
        ._index = self._store.items.len,
    });

    var order = 0;
    var min = std.math.inf(usize);
    for (self._store.items, 0..) |spot, index| {
        if (spot._start < end) continue;
        const diff = spot._start - end;
        if (diff < min) {
            min = diff;
            order = index;
        }
    }

    try self._store.insert(self._allocator, order, new_str);

    return new_str;
}

pub fn getOrCreate(self: *Strings, str: []const u8) !Spot {
    for (self._store.items) |spot| {
        const spotStr = self._buf[spot.start..spot.end];
        if (std.mem.eql(u8, spotStr, str)) return spotStr;
    }
    return try self.create(str);
}

/// Searches for an available spot for a string with a specific number of characters.
/// - `len`: the length of the required string.
/// @return: the index of the available spot in the buf, if found, otherwise return -1.
fn findSpot(self: *Strings, len: usize) usize {
    if (self._store.items.len == 0 and len <= PAGE_SIZE) return 0;

    var last_end = 0;
    for (self._store.items) |spot| {
        const avai_len = spot._start - last_end;
        if (len <= avai_len) return last_end;
        last_end = spot._end;
    }

    return -1;
}

/// Extend the current buffer and return the start index of the extent.
/// - `len`: the length of the required string.
/// @return: the index of the available spot in the buf.
fn extendTheBuffer(self: *Strings, _: usize) !usize {
    // TODO
    const i = self._buf.len;
    return i;
}

/// A spot in the strings type buffer
const Spot = struct {
    _factory: *Strings,
    _start: usize,
    _end: usize,
    _index: usize,

    pub fn init(s: Spot) *Spot {
        return &Spot{
            ._factory = s._factory,
            ._start = s._start,
            ._end = s._end,
            ._index = s._index,
        };
    }

    pub fn deinit(self: *Spot) void {
        self._factory._store.orderedRemove(self._index);
    }

    pub fn read(self: *Spot) []const u8 {
        return self._factory._buf[self._start..self._end];
    }

    pub fn getIndex(self: *Spot) usize {
        return self._index;
    }
};

const std = @import("std");
const sdl = @import("../sdl.zig");

const Callback = *const fn () void;
pub const Key = enum { A, S, D, W, ESC };

pub const EventManager = struct {
    var keyDownFnHash = std.AutoHashMap(Key, std.ArrayList(Callback)).init(std.heap.page_allocator);
    var keyUpFnHash = std.AutoHashMap(Key, std.ArrayList(Callback)).init(std.heap.page_allocator);

    pub fn deinit(_: *EventManager) void {
        keyDownFnHash.deinit();
        keyUpFnHash.deinit();
    }

    pub fn invokeEventLoop(self: *EventManager) sdl.c.SDL_Event {
        var event: sdl.c.SDL_Event = undefined;
        while (sdl.c.SDL_PollEvent(&event)) {
            switch (event.type) {
                sdl.c.SDL_EVENT_KEY_DOWN => {
                    switch (event.key.scancode) {
                        sdl.c.SDL_SCANCODE_ESCAPE => self.keyDown(Key.ESC),
                        sdl.c.SDL_SCANCODE_A => self.keyDown(Key.A),
                        sdl.c.SDL_SCANCODE_D => self.keyDown(Key.D),
                        sdl.c.SDL_SCANCODE_W => self.keyDown(Key.W),
                        sdl.c.SDL_SCANCODE_S => self.keyDown(Key.S),
                        else => {},
                    }
                },
                sdl.c.SDL_EVENT_KEY_UP => {
                    switch (event.key.scancode) {
                        sdl.c.SDL_SCANCODE_ESCAPE => self.keyUp(Key.ESC),
                        sdl.c.SDL_SCANCODE_A => self.keyUp(Key.A),
                        sdl.c.SDL_SCANCODE_D => self.keyUp(Key.D),
                        sdl.c.SDL_SCANCODE_W => self.keyUp(Key.W),
                        sdl.c.SDL_SCANCODE_S => self.keyUp(Key.S),
                        else => {},
                    }
                },
                else => return event,
            }
        }
        return event;
    }

    fn keyDown(_: *EventManager, key: Key) void {
        if (keyDownFnHash.get(key)) |callbacks| {
            for (callbacks.items) |callback| callback();
        }
    }

    fn keyUp(_: *EventManager, key: Key) void {
        if (keyUpFnHash.get(key)) |callbacks| {
            for (callbacks.items) |callback| callback();
        }
    }

    pub fn onKeyDown(_: *EventManager, key: Key, callback: Callback) !void {
        var arr = keyDownFnHash.getPtr(key) orelse blk: {
            const tmp = std.ArrayList(Callback).empty;
            try keyDownFnHash.put(key, tmp);
            break :blk keyDownFnHash.getPtr(key);
        };
        try arr.?.append(std.heap.page_allocator, callback);
    }

    pub fn onKeyUp(_: *EventManager, key: Key, callback: Callback) !void {
        var arr = keyUpFnHash.getPtr(key) orelse blk: {
            const tmp = std.ArrayList(Callback).empty;
            try keyUpFnHash.put(key, tmp);
            break :blk keyUpFnHash.getPtr(key);
        };
        try arr.?.append(std.heap.page_allocator, callback);
    }
};

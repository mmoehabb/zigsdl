const c = @cImport({
    @cInclude("SDL3/SDL.h");
});
const HashMap = @import("std").AutoHashMap;
const ArrayList = @import("std").ArrayList;
const std = @import("std");

const Callback = *fn () void;
pub const Key = enum { A, S, D, W, ESC };

pub const EventManager = struct {
    var keyDownFnHash = HashMap(Key, ArrayList(Callback)).init(std.heap.page_allocator);
    var keyUpFnHash = HashMap(Key, ArrayList(Callback)).init(std.heap.page_allocator);

    pub fn deinit(_: *EventManager) void {
        keyDownFnHash.deinit();
        keyUpFnHash.deinit();
    }

    pub fn invokeEventLoop(self: *EventManager) c.SDL_Event {
        var event: c.SDL_Event = undefined;
        while (c.SDL_PollEvent(&event)) {
            switch (event.type) {
                c.SDL_EVENT_KEY_DOWN => {
                    switch (event.key.scancode) {
                        c.SDL_SCANCODE_ESCAPE => self.keyDown(Key.ESC),
                        c.SDL_SCANCODE_A => self.keyDown(Key.A),
                        c.SDL_SCANCODE_D => self.keyDown(Key.D),
                        c.SDL_SCANCODE_W => self.keyDown(Key.W),
                        c.SDL_SCANCODE_S => self.keyDown(Key.S),
                        else => {},
                    }
                },
                c.SDL_EVENT_KEY_UP => {
                    switch (event.key.scancode) {
                        c.SDL_SCANCODE_ESCAPE => self.keyUp(Key.ESC),
                        c.SDL_SCANCODE_A => self.keyUp(Key.A),
                        c.SDL_SCANCODE_D => self.keyUp(Key.D),
                        c.SDL_SCANCODE_W => self.keyUp(Key.W),
                        c.SDL_SCANCODE_S => self.keyUp(Key.S),
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

    pub fn onKeyDown(_: *EventManager, key: Key, callback: Callback) void {
        if (keyDownFnHash.get(key) == undefined) {
            const arr = ArrayList(Callback).init(std.heap.page_allocator);
            arr.append(callback);
            keyDownFnHash.put(key, arr);
            return;
        }
        const arr = keyDownFnHash.get(key);
        arr.append(callback);
    }

    pub fn onKeyUp(_: *EventManager, key: Key, callback: Callback) void {
        if (keyUpFnHash.get(key) == undefined) {
            const arr = ArrayList(Callback).init(std.heap.page_allocator);
            arr.append(callback);
            keyUpFnHash.put(key, arr);
            return;
        }
        const arr = keyUpFnHash.get(key);
        arr.append(callback);
    }
};

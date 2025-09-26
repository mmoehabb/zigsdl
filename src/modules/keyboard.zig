const c = @cImport({
    @cInclude("SDL3/SDL.h");
});
const HashMap = @import("std").AutoHashMap;
const ArrayList = @import("std").ArrayList;
const std = @import("std");

const Key = enum { A, S, D, W, ESC };
const Callback = fn () void;

const Keyboard = struct {
    _allocator: std.mem.Allocator,
    _keyDownFnHash: HashMap(Key, ArrayList(Callback)),
    _keyUpFnHash: HashMap(Key, ArrayList(Callback)),

    pub fn init(self: *Keyboard) void {
        const gpa = std.heap.GeneralPurposeAllocator(.{}){};
        self._allocator = gpa.allocator();
        self._keyDownFnHash = HashMap(Key, ArrayList(Callback)).init(self._allocator);
        self._keyUpFnHash = HashMap(Key, ArrayList(Callback)).init(self._allocator);
    }

    pub fn deinit(self: *Keyboard) void {
        self._keyDownFnHash.deinit();
        self._keyUpFnHash.deinit();
    }

    pub fn invokeEventLoop(self: *Keyboard) void {
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
                else => {},
            }
        }
    }

    fn keyDown(self: *Keyboard, key: Key) void {
        if (self._keyDownFnHash.get(key)) |callbacks| {
            for (callbacks) |callback| callback();
        }
    }

    fn keyUp(self: *Keyboard, key: Key) void {
        if (self._keyUpFnHash.get(key)) |callbacks| {
            for (callbacks) |callback| callback();
        }
    }

    fn onKeyDown(self: *Keyboard, key: Key, callback: Callback) void {
        if (self._keyDownFnHash.get(key) == undefined) {
            const arr = ArrayList(Callback).init(self._allocator);
            arr.append(callback);
            self._keyDownFnHash.put(key, arr);
            return;
        }
        const arr = self._keyDownFnHash.get(key);
        arr.append(callback);
    }

    fn onKeyUp(self: *Keyboard, key: Key, callback: Callback) void {
        if (self._keyUpFnHash.get(key) == undefined) {
            const arr = ArrayList(Callback).init(self._allocator);
            arr.append(callback);
            self._keyUpFnHash.put(key, arr);
            return;
        }
        const arr = self._keyUpFnHash.get(key);
        arr.append(callback);
    }
};

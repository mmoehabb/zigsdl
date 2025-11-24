//! This component can be considered as a collection of scenes.

const std = @import("std");
const sdl = @import("../sdl.zig");

const EventManager = @import("event-manager.zig");
const Scene = @import("scene.zig");
const types = @import("../types/mod.zig");

const Screen = @This();

/// The title of the SDL window.
title: []const u8,

/// The width of the screen.
width: c_int,

/// The height of the screen.
height: c_int,

/// The duration, in milliseconds, between each frame and the other.
rate: u32,

/// The screen [lifecycle](#root.types.lifecycle).
lifecycle: *const types.LifeCycle = &types.LifeCycle{},

_em: EventManager,

_scene: ?*Scene = null,
_window: ?*sdl.c.SDL_Window = null,
_renderer: ?*sdl.c.SDL_Renderer = null,
_opened: bool = false,

pub fn init(params: struct {
    allocator: std.mem.Allocator,
    title: []const u8,
    width: c_int,
    height: c_int,
    rate: u32,
}) Screen {
    return Screen{
        .title = params.title,
        .width = params.width,
        .height = params.height,
        .rate = params.rate,
        ._em = EventManager.init(params.allocator),
    };
}

/// Closes the screen if it's already open.
pub fn deinit(self: *Screen) void {
    if (!self._opened) return;
    self.close() catch std.log.err("Screen: something went wrong while closing!", .{});
}

pub fn open(self: *Screen) !void {
    if (self.lifecycle.preOpen) |func| func(self);

    if (!sdl.c.SDL_Init(sdl.c.SDL_INIT_VIDEO)) {
        sdl.c.SDL_Log("Unable to initialize SDL Video: %s", sdl.c.SDL_GetError());
        return error.SDLInitializationFailed;
    }

    if (!sdl.c.SDL_Init(sdl.c.SDL_INIT_AUDIO)) {
        sdl.c.SDL_Log("Unable to initialize SDL Audio: %s", sdl.c.SDL_GetError());
        return error.SDLInitializationFailed;
    }

    if (!sdl.c.TTF_Init()) {
        return error.TTFInitializationFailed;
    }

    self._window = sdl.c.SDL_CreateWindow(
        self.title.ptr,
        self.width,
        self.height,
        sdl.c.SDL_WINDOW_OPENGL,
    ) orelse {
        sdl.c.SDL_Log("Unable to create window: %s", sdl.c.SDL_GetError());
        return error.SDLInitializationFailed;
    };

    self._renderer = sdl.c.SDL_CreateRenderer(self._window, null) orelse {
        sdl.c.SDL_Log("Unable to create renderer: %s", sdl.c.SDL_GetError());
        return error.SDLInitializationFailed;
    };

    if (self._scene) |s| try s.start();

    if (self.lifecycle.postOpen) |func| func(self);

    self._opened = true;
    while (self._opened) try self.update();
}

fn update(self: *Screen) !void {
    if (self.lifecycle.preUpdate) |func| func(self);

    const event = try self._em.invokeEventLoop();
    if (event.type == sdl.c.SDL_EVENT_QUIT) return try self.close();

    _ = sdl.c.SDL_RenderClear(self._renderer);
    if (self._scene) |s| try s.update(self._renderer.?);
    _ = sdl.c.SDL_SetRenderDrawColor(self._renderer, 0, 0, 0, 255);
    _ = sdl.c.SDL_RenderPresent(self._renderer);

    if (self.lifecycle.postUpdate) |func| func(self);
    sdl.c.SDL_Delay(self.rate);
}

/// Deinits the local fields and quits/destroys the SDL stuff.
pub fn close(self: *Screen) !void {
    if (self.lifecycle.preClose) |func| func(self);

    _ = self._renderer orelse return error.ScreenNotInitialized;
    _ = self._window orelse return error.ScreenNotInitialized;

    self._em.deinit();

    self._opened = false;
    if (self.lifecycle.postClose) |func| func(self);

    sdl.c.TTF_Quit();
    sdl.c.SDL_DestroyRenderer(self._renderer);
    sdl.c.SDL_DestroyWindow(self._window);
    sdl.c.SDL_Quit();
}

pub fn setScene(self: *Screen, newscene: *Scene) void {
    self._scene = newscene;
    self._scene.?.setScreen(self);
}

pub fn getEventManager(self: *Screen) *EventManager {
    return &self._em;
}

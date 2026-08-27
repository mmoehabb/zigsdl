//! This component can be considered as a collection of scenes.

const std = @import("std");
const sdl = @import("sdl");

const PluginManager = @import("plugin-manager.zig");
const Scene = @import("scene.zig");
const EventManager = @import("../plugins/event-manager.zig");
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

_scene: ?*Scene = null,
_window: ?*sdl.SDL_Window = null,
_renderer: ?*sdl.SDL_Renderer = null,
_opened: bool = false,
_em: ?*EventManager,

pub fn init(
    params: struct {
        title: []const u8,
        width: c_int,
        height: c_int,
        rate: u32,
    },
) !Screen {
    if (PluginManager.isInitialized() == false) {
        std.log.err("Screen.init: you must initialize the PluginManager first.", .{});
        return error.PluginManagerRequired;
    }
    const eventManager = PluginManager.get(EventManager, "EventManager");
    return Screen{
        .title = params.title,
        .width = params.width,
        .height = params.height,
        .rate = params.rate,
        ._em = eventManager,
    };
}

/// Closes the screen if it's already open.
pub fn deinit(self: *Screen) void {
    if (!self._opened) return;
    self.close() catch std.log.err("Screen: something went wrong while closing!", .{});
}

pub fn open(self: *Screen) !void {
    if (self.lifecycle.preOpen) |func| func(self);

    if (!sdl.SDL_Init(sdl.SDL_INIT_VIDEO)) {
        sdl.SDL_Log("Unable to initialize SDL Video: %s", sdl.SDL_GetError());
        return error.SDLInitializationFailed;
    }

    if (!sdl.SDL_Init(sdl.SDL_INIT_AUDIO)) {
        sdl.SDL_Log("Unable to initialize SDL Audio: %s", sdl.SDL_GetError());
    }

    if (!sdl.TTF_Init()) {
        return error.TTFInitializationFailed;
    }

    self._window = sdl.SDL_CreateWindow(
        self.title.ptr,
        self.width,
        self.height,
        sdl.SDL_WINDOW_OPENGL,
    ) orelse {
        sdl.SDL_Log("Unable to create window: %s", sdl.SDL_GetError());
        return error.SDLInitializationFailed;
    };

    if (self._em) |em| em.setActiveWindow(self._window);

    self._renderer = sdl.SDL_CreateRenderer(self._window, null) orelse {
        sdl.SDL_Log("Unable to create renderer: %s", sdl.SDL_GetError());
        return error.SDLInitializationFailed;
    };

    if (self._scene) |s| try s.start();

    if (self.lifecycle.postOpen) |func| func(self);

    self._opened = true;
    while (self._opened) try self.update();
}

fn update(self: *Screen) !void {
    if (self.lifecycle.preUpdate) |func| func(self);

    if (self._em) |em| {
        const event = try em.invokeEventLoop();
        if (event.type == sdl.SDL_EVENT_QUIT) return try self.close();
    }

    const dt: f32 = @as(f32, @floatFromInt(self.rate)) / 1000.0; // ms to seconds

    _ = sdl.SDL_RenderClear(self._renderer);
    if (self._scene) |s| {
        try s.update(dt);
        try s.draw(self._renderer.?);
    }
    // TODO: get the background color from user input
    _ = sdl.SDL_SetRenderDrawColor(self._renderer, 0, 0, 0, 255);
    _ = sdl.SDL_RenderPresent(self._renderer);

    if (self.lifecycle.postUpdate) |func| func(self);
    sdl.SDL_Delay(self.rate);
}

/// Deinits the local fields and quits/destroys the SDL stuff.
pub fn close(self: *Screen) !void {
    if (self.lifecycle.preClose) |func| func(self);

    _ = self._renderer orelse return error.ScreenNotInitialized;
    _ = self._window orelse return error.ScreenNotInitialized;

    self._opened = false;
    if (self.lifecycle.postClose) |func| func(self);

    sdl.TTF_Quit();
    sdl.SDL_DestroyRenderer(self._renderer);
    sdl.SDL_DestroyWindow(self._window);
    sdl.SDL_Quit();
}

pub fn setScene(self: *Screen, newscene: *Scene) void {
    self._scene = newscene;
    self._scene.?.setScreen(self);
}

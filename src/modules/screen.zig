const std = @import("std");
const sdl = @import("../sdl.zig");

const EventManager = @import("event-manager.zig").EventManager;
const Scene = @import("scene.zig").Scene;
const types = @import("../types/mod.zig");

pub const Screen = struct {
    title: []const u8,
    width: c_int,
    height: c_int,
    rate: u32,
    lifecycle: *const types.common.LifeCycle = &types.common.LifeCycle{
        .preOpen = null,
        .postOpen = null,
        .preUpdate = null,
        .postUpdate = null,
        .preClose = null,
        .postClose = null,
    },
    em: EventManager,

    var closed: bool = false;
    var scene: ?*Scene = null;
    var window: ?*sdl.c.SDL_Window = null;
    var renderer: ?*sdl.c.SDL_Renderer = null;

    pub fn new(title: []const u8, width: c_int, height: c_int, rate: u32) Screen {
        return Screen{
            .title = title,
            .width = width,
            .height = height,
            .rate = rate,
            .em = EventManager{},
        };
    }

    pub fn open(self: *Screen) !void {
        if (self.lifecycle.preOpen) |func| func(self);

        if (!sdl.c.SDL_Init(sdl.c.SDL_INIT_VIDEO)) {
            sdl.c.SDL_Log("Unable to initialize SDL: %s", sdl.c.SDL_GetError());
            return error.SDLInitializationFailed;
        }

        if (!sdl.c.TTF_Init()) {
            return error.TTFInitializationFailed;
        }

        window = sdl.c.SDL_CreateWindow(self.title.ptr, self.width, self.height, sdl.c.SDL_WINDOW_OPENGL) orelse {
            sdl.c.SDL_Log("Unable to create window: %s", sdl.c.SDL_GetError());
            return error.SDLInitializationFailed;
        };

        renderer = sdl.c.SDL_CreateRenderer(window, null) orelse {
            sdl.c.SDL_Log("Unable to create renderer: %s", sdl.c.SDL_GetError());
            return error.SDLInitializationFailed;
        };

        if (scene) |s| try s.start();

        if (self.lifecycle.postOpen) |func| func(self);

        closed = false;
        while (!closed) try self.update();
    }

    fn update(self: *Screen) !void {
        if (self.lifecycle.preUpdate) |func| func(self);

        const event = try self.em.invokeEventLoop();
        if (event.type == sdl.c.SDL_EVENT_QUIT) return try self.close();

        _ = sdl.c.SDL_RenderClear(renderer);
        if (scene) |s| try s.update(renderer.?);
        _ = sdl.c.SDL_SetRenderDrawColor(renderer, 0, 0, 0, 255);
        _ = sdl.c.SDL_RenderPresent(renderer);

        if (self.lifecycle.postUpdate) |func| func(self);
        sdl.c.SDL_Delay(self.rate);
    }

    pub fn close(self: *Screen) !void {
        if (self.lifecycle.preClose) |func| func(self);

        _ = renderer orelse return error.ScreenNotInitialized;
        _ = window orelse return error.ScreenNotInitialized;

        if (scene) |s| try s.deinit();
        self.em.deinit();

        closed = true;
        if (self.lifecycle.postClose) |func| func(self);

        sdl.c.TTF_Quit();
        sdl.c.SDL_DestroyRenderer(renderer);
        sdl.c.SDL_DestroyWindow(window);
        sdl.c.SDL_Quit();
    }

    pub fn setScene(self: *Screen, newscene: *Scene) void {
        scene = newscene;
        scene.?.setScreen(self);
    }
};

const c = @cImport({
    @cInclude("SDL3/SDL.h");
});
const std = @import("std");

const Scene = @import("scene.zig").Scene;
const EventManager = @import("event-manager.zig").EventManager;
const LifeCycle = @import("../types/common.zig").LifeCycle;

pub const Screen = struct {
    title: []const u8,
    width: c_int,
    height: c_int,
    lifecycle: *const LifeCycle,
    eventManager: EventManager,

    var closed: bool = false;
    var scene: ?*Scene = null;
    var window: ?*c.SDL_Window = null;
    var renderer: ?*c.SDL_Renderer = null;

    pub fn new(title: []const u8, width: c_int, height: c_int, lifecycle: *const LifeCycle) Screen {
        return Screen{
            .title = title,
            .width = width,
            .height = height,
            .lifecycle = lifecycle,
            .eventManager = EventManager{},
        };
    }

    pub fn open(self: *Screen) !void {
        if (self.lifecycle.preOpen) |func| func();

        if (!c.SDL_Init(c.SDL_INIT_VIDEO)) {
            c.SDL_Log("Unable to initialize SDL: %s", c.SDL_GetError());
            return error.SDLInitializationFailed;
        }

        window = c.SDL_CreateWindow(self.title.ptr, self.width, self.height, c.SDL_WINDOW_OPENGL) orelse {
            c.SDL_Log("Unable to create window: %s", c.SDL_GetError());
            return error.SDLInitializationFailed;
        };

        renderer = c.SDL_CreateRenderer(window, null) orelse {
            c.SDL_Log("Unable to create renderer: %s", c.SDL_GetError());
            return error.SDLInitializationFailed;
        };

        if (scene) |s| try s.start();

        if (self.lifecycle.postOpen) |func| func();

        closed = false;
        while (!closed) try self.update();
    }

    fn update(self: *Screen) !void {
        if (self.lifecycle.preUpdate) |func| func();

        const event = self.eventManager.invokeEventLoop();
        if (event.type == c.SDL_EVENT_QUIT) return try self.close();

        _ = c.SDL_RenderClear(renderer);
        if (scene) |s| try s.update(renderer.?);
        _ = c.SDL_SetRenderDrawColor(renderer, 0, 0, 0, 255);
        _ = c.SDL_RenderPresent(renderer);

        if (self.lifecycle.postUpdate) |func| func();
        c.SDL_Delay(10);
    }

    pub fn close(self: *Screen) !void {
        if (self.lifecycle.preClose) |func| func();

        _ = renderer orelse return error.ScreenNotInitialized;
        _ = window orelse return error.ScreenNotInitialized;

        if (scene) |s| s.deinit();
        self.eventManager.deinit();

        closed = true;
        if (self.lifecycle.postClose) |func| func();

        c.SDL_DestroyRenderer(renderer);
        c.SDL_DestroyWindow(window);
        c.SDL_Quit();
    }

    pub fn setScene(_: *Screen, newscene: *Scene) void {
        scene = newscene;
        _ = renderer orelse try scene.?.start();
    }
};

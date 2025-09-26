const c = @cImport({
    @cInclude("SDL2/SDL.h");
});

const Scene = @import("scene.zig").Scene;
const LifeCycle = @import("../types/common.zig").LifeCycle;

pub const Screen = struct {
    title: []const u8,
    width: usize,
    hight: usize,
    lifecycle: LifeCycle,

    _closed: bool,
    _scene: ?*Scene,
    _window: ?*c.SDL_Window,
    _renderer: ?*c.SDL_Renderer,

    pub fn open(self: *Screen) !void {
        if (self.lifecycle.preOpen != undefined) self.lifecycle.preOpen();

        if (c.SDL_Init(c.SDL_INIT_VIDEO) != 0) {
            c.SDL_Log("Unable to initialize SDL: %s", c.SDL_GetError());
            return error.SDLInitializationFailed;
        }

        self._window = c.SDL_CreateWindow(self.title, self.width, self.hight, c.SDL_WINDOW_OPENGL) orelse {
            c.SDL_Log("Unable to create window: %s", c.SDL_GetError());
            return error.SDLInitializationFailed;
        };

        self._renderer = c.SDL_CreateRenderer(self._window, null) orelse {
            c.SDL_Log("Unable to create renderer: %s", c.SDL_GetError());
            return error.SDLInitializationFailed;
        };

        if (self._scene != undefined) self._scene.start();

        if (self.lifecycle.postOpen != undefined) self.lifecycle.postOpen();

        self._closed = false;
        while (!self._closed) self.update();
    }

    fn update(self: *Screen) !void {
        if (self.lifecycle.preUpdate != undefined) self.lifecycle.preUpdate();

        _ = c.SDL_RenderClear(self._renderer);
        if (self._scene != undefined) {
            try self._scene.?.update(self._renderer);
        }
        c.SDL_RenderPresent(self._renderer);

        if (self.lifecycle.postUpdate != undefined) self.lifecycle.postUpdate();
        c.SDL_Delay(10);
    }

    pub fn close(self: *Screen) !void {
        if (self.lifecycle.preClose != undefined) self.lifecycle.preClose();

        if (self._renderer == undefined or self._window == undefined) {
            return error.ScreenNotInitialized;
        }

        if (self._scene != undefined) self._scene.deinit();

        self._closed = true;
        if (self.lifecycle.postClose != undefined) self.lifecycle.postClose();

        c.SDL_DestroyRenderer(self._renderer);
        c.SDL_DestroyWindow(self._window);
        c.SDL_Quit();
    }

    pub fn setScene(self: *Screen, scene: *Scene) void {
        self._scene = scene.init();
        if (self._renderer != undefined) self._scene.start();
    }
};

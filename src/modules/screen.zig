const c = @cImport({
    @cInclude("SDL2/SDL.h");
});

const Scene = @import("scene.zig").Scene;
const LifeCycle = @import("../types/common.zig").LifeCycle;

pub const Screen = struct {
    title: []const u8,
    width: usize,
    hight: usize,
    closed: bool,

    scene: ?*Scene,
    lifecycle: LifeCycle,

    window: ?*c.SDL_Window,
    renderer: ?*c.SDL_Renderer,

    pub fn open(self: *Screen) !void {
        if (self.lifecycle.preOpen != undefined) self.lifecycle.preOpen();

        if (c.SDL_Init(c.SDL_INIT_VIDEO) != 0) {
            c.SDL_Log("Unable to initialize SDL: %s", c.SDL_GetError());
            return error.SDLInitializationFailed;
        }

        self.window = c.SDL_CreateWindow(self.title, c.SDL_WINDOWPOS_UNDEFINED, c.SDL_WINDOWPOS_UNDEFINED, self.width, self.hight, c.SDL_WINDOW_OPENGL) orelse {
            c.SDL_Log("Unable to create window: %s", c.SDL_GetError());
            return error.SDLInitializationFailed;
        };

        self.renderer = c.SDL_CreateRenderer(self.window, -1, 0) orelse {
            c.SDL_Log("Unable to create renderer: %s", c.SDL_GetError());
            return error.SDLInitializationFailed;
        };

        if (self.lifecycle.postOpen != undefined) self.lifecycle.postOpen();

        self.closed = false;
        while (!self.closed) self.update();
    }

    pub fn close(self: *Screen) !void {
        if (self.lifecycle.preClose != undefined) self.lifecycle.preClose();

        if (!self.renderer or !self.window) {
            return error.ScreenNotInitialized;
        }

        self.closed = true;
        if (self.lifecycle.postClose != undefined) self.lifecycle.postClose();

        c.SDL_DestroyRenderer(self.renderer);
        c.SDL_DestroyWindow(self.window);
        c.SDL_Quit();
    }

    fn update(self: *Screen) !void {
        if (self.lifecycle.preUpdate != undefined) self.lifecycle.preUpdate();

        _ = c.SDL_RenderClear(self.renderer);
        if (self.scene != undefined) {
            try self.scene.?.update(self.renderer);
        }
        c.SDL_RenderPresent(self.renderer);

        if (self.lifecycle.postUpdate != undefined) self.lifecycle.postUpdate();
        c.SDL_Delay(10);
    }
};

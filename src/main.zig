const c = @cImport({
    @cInclude("SDL3/SDL.h");
});
const std = @import("std");
const Screen = @import("modules/screen.zig").Screen;

pub fn main() !void {
    if (!c.SDL_Init(c.SDL_INIT_VIDEO)) {
        c.SDL_Log("Unable to initialize SDL: %s", c.SDL_GetError());
        return error.SDLInitializationFailed;
    }
    defer c.SDL_Quit();

    const window = c.SDL_CreateWindow("My Game Window", 800, 600, c.SDL_WINDOW_OPENGL) orelse {
        c.SDL_Log("Unable to create window: %s", c.SDL_GetError());
        return error.SDLInitializationFailed;
    };
    defer c.SDL_DestroyWindow(window);

    const renderer = c.SDL_CreateRenderer(window, null) orelse {
        c.SDL_Log("Unable to create renderer: %s", c.SDL_GetError());
        return error.SDLInitializationFailed;
    };
    defer c.SDL_DestroyRenderer(renderer);

    var quit = false;

    var x: f32 = 20;
    var y: f32 = 20;

    var keyA: bool = false;
    var keyD: bool = false;
    var keyW: bool = false;
    var keyS: bool = false;

    while (!quit) {
        var event: c.SDL_Event = undefined;
        while (c.SDL_PollEvent(&event)) {
            switch (event.type) {
                c.SDL_EVENT_QUIT => {
                    quit = true;
                },
                c.SDL_EVENT_KEY_DOWN => {
                    switch (event.key.scancode) {
                        c.SDL_SCANCODE_ESCAPE => quit = true,
                        c.SDL_SCANCODE_A => keyA = true,
                        c.SDL_SCANCODE_D => keyD = true,
                        c.SDL_SCANCODE_W => keyW = true,
                        c.SDL_SCANCODE_S => keyS = true,
                        else => {},
                    }
                },
                c.SDL_EVENT_KEY_UP => {
                    switch (event.key.scancode) {
                        c.SDL_SCANCODE_A => keyA = false,
                        c.SDL_SCANCODE_D => keyD = false,
                        c.SDL_SCANCODE_W => keyW = false,
                        c.SDL_SCANCODE_S => keyS = false,
                        else => {},
                    }
                },
                else => {},
            }
        }

        if (keyA == true) x = @max(x - 5, 0);
        if (keyD == true) x = @min(x + 5, 800 - 20);
        if (keyW == true) y = @max(y - 5, 0);
        if (keyS == true) y = @min(y + 5, 600 - 20);

        _ = c.SDL_RenderClear(renderer);

        _ = c.SDL_SetRenderDrawColor(renderer, 100, 200, 50, 255);
        _ = c.SDL_RenderFillRect(renderer, &c.SDL_FRect{
            .x = x,
            .y = y,
            .w = 20,
            .h = 20,
        });

        _ = c.SDL_SetRenderDrawColor(renderer, 0, 0, 0, 255);
        _ = c.SDL_RenderPresent(renderer);

        c.SDL_Delay(10);
    }
}

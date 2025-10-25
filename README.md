![cova_icon_v2 1](./splash.png)

[![Static Badge](https://img.shields.io/badge/v0.15.1(stable)-orange?logo=Zig&logoColor=Orange&label=Zig&labelColor=Orange)](https://ziglang.org/download/)
[![Static Badge](https://img.shields.io/badge/v0.0.1-blue?logo=GitHub&label=Release)](https://github.com/mmoehabb/zigsdl/releases/tag/v0.0.1)
[![Static Badge](https://img.shields.io/badge/MIT-silver?label=License)](https://github.com/mmoehabb/zigsdl/blob/main/LICENSE)

## About

A relatively easy-to-pick, simple, and straightforward package that developers can use in order to write graphic applications in [Zig](https://ziglang.org/). Just as the name indicates it's build on [SDL3](https://www.libsdl.org/).

- [Install SDL3](#install-sdl3)
- [Install ZigSDL](#install-zigsdl)
- [Run an Example](#run-an-example)
- [Extend the Functionality](#extend-the-functionality)
- [TODOs](#todos)

## Install ZigSDL

You can use ZigSDL in your zig project by fetching it as follows:

```bash
zig fetch --save git+https://github.com/mmoehabb/zigsdl.git
```

And then add it as an import in your exe root module:

```zig
const exe = b.addExecutable(.{
    .name = "your-project",
    .root_module = exe_mod,
});

const zigsdl_dep = b.dependency("zigsdl", .{
    .target = target,
    .optimize = optimize,
});

const zigsdl_mod = zigsdl_dep.module("zigsdl");

exe.root_module.addImport("zigsdl", zigsdl_mod);
```

> Make sure to install SDL3 first.

## Run an Example

First ensure to install SDL3 on your machine, and Zig of course. Choose any example file in the examples directory, and then run it with the following command:

> Note: compatible only with zig versions ^0.15.0

  ```bash
  zig build <example>
  ```

For instance:

  ```bash
  zig build moving_box_example
  ```

## Extend the Functionality

I bet if you gave the code a look, you'd already know how to extend it and make a functional game with ZigSDL. Here's the moving_box_example zig file:

```zig
const zigsdl = @import("zigsdl");

pub fn main() !void {
    // create a drawable object
    const rect = zigsdl.drawables.Rect.new(.{ .w = 20, .h = 20, .d = 1 }, .{ .g = 255 });
    var obj = zigsdl.modules.Object{
        .position = .{ .x = 20, .y = 20, .z = 1 },
        .rotation = .{ .x = 0, .y = 0, .z = 0 },
        .drawable = &rect,
    };

    // add movement script to the object
    try obj.addScript(zigsdl.scripts.Movement.new(5, true));

    // create a scene and add the drawable obj into it
    var scene = zigsdl.modules.Scene.new();
    try scene.addObject(&obj);

    // create a screen, attach the scene to it, and open it
    var screen = zigsdl.modules.Screen.new("Simple Game", 320, 320, 1000 / 60);
    screen.setScene(&scene);
    try screen.open();
}
```

You may add as many objects as you want in the scene, you can easily add different functionalities and behaviour to your objects by adding scripts into them, and you may use ZigSDL pre-defined scripts or write your own ones as follows:

```zig
const zigsdl = @import("zigsdl");

pub fn main() !void {
    // create a drawable object
    var rect = zigsdl.drawables.Rect.new(.{ .w = 20, .h = 20, .d = 1 }, .{ .g = 255 });

    var obj = zigsdl.modules.Object{
        .position = .{ .x = 20, .y = 20, .z = 1 },
        .rotation = .{ .x = 0, .y = 0, .z = 0 },
        .drawable = &rect.toDrawable(),
    };

    // add movement script to the object
    try obj.addScript(zigsdl.scripts.Movement.new(5, true));

    // create a scene and add the obj into it
    var scene = zigsdl.modules.Scene.new();
    try scene.addObject(&obj);

    // create a screen, attach the scene to it, and open it
    var screen = zigsdl.modules.Screen.new("Simple Game", 320, 320, 1000 / 60);
    screen.setScene(&scene);
    try screen.open();
}
```

You may add as many objects as you want in the scene, you can easily add different functionalities and behaviour to your objects by adding scripts into them, and you may use ZigSDL pre-defined scripts or write your own ones as follows:

```zig
const zigsdl = @import("zigsdl");

pub const Rect = struct {
    dim: zigsdl.types.common.Dimensions,
    color: zigsdl.types.common.Color = .{},
    _draw_strategy: zigsdl.modules.DrawStrategy = zigsdl.modules.DrawStrategy{
        .draw = draw,
        .destroy = destroy,
    },

    pub fn new(dim: zigsdl.types.common.Dimensions, color: zigsdl.types.common.Color) Rect {
        return Rect{
            .dim = dim,
            .color = color,
        };
    }

    pub fn toDrawable(self: *Rect) zigsdl.modules.Drawable {
        return zigsdl.modules.Drawable{
            .dim = self.dim,
            .color = self.color,
            .drawStrategy = &self._draw_strategy,
        };
    }

    fn draw(
        _: *const zigsdl.modules.DrawStrategy,
        renderer: *zigsdl.sdl.SDL_Renderer,
        p: zigsdl.types.common.Position,
        _: zigsdl.types.common.Rotation,
        dim: zigsdl.types.common.Dimensions,
    ) !void {
        if (!sdl.c.SDL_RenderFillRect(renderer, &sdl.c.SDL_FRect{
            .x = p.x,
            .y = p.y,
            .w = dim.w,
            .h = dim.h,
        })) return error.RenderFailed;
    }

    fn destroy(_: *const zigsdl.modules.DrawStrategy) void {}
};
```

Moreover, you may access SDL indirectly from ZigSDL, and use SDL facilities in your scripts:

```zig
const sdl = @import("zigsdl").sdl;
sdl.SDL_RenderFillRect(...);
```

## Install SDL3

This guide provides brief instructions for installing SDL3 on various operating systems to support projects like `zigsdl`.

> Generated by Grok

### Windows

- **Using vcpkg**:

  ```bash
  vcpkg install sdl3
  vcpkg install sdl3_ttf
  ```

- **Manual Installation**:

  - Download the SDL3 development libraries from [libsdl.org](https://www.libsdl.org).
  - Extract the archive and add the `include` and `lib` directories to your compiler's include and library paths.
  - Ensure `SDL3.dll` is in your executable's directory or system PATH.

### macOS

- **Using Homebrew**:

  ```bash
  brew install sdl3
  brew install sdl3_ttf
  ```

- **Manual Installation**:

  - Download the SDL3 DMG from [libsdl.org](https://www.libsdl.org).
  - Copy `SDL3.framework` to `/Library/Frameworks` or your project directory.
  - Link against the framework in your build configuration.

### Linux (Ubuntu/Debian)

- **Using apt**:

  ```bash
  sudo apt-get update
  sudo apt-get install libsdl3-dev
  sudo apt-get install libsdl3_ttf-dev
  ```

- **Manual Installation**:

  - Download the SDL3 source from [libsdl.org](https://www.libsdl.org).

  - Build and install:

    ```bash
    ./configure
    make
    sudo make install
    ```

### Linux (Fedora)

- **Using dnf**:

  ```bash
  sudo dnf install SDL3-devel
  sudo dnf install SDL3_ttf-devel
  ```

### Linux (Arch)

- **Using paru**:

  ```bash
  paru -S sdl3
  paru -S sdl3_ttf
  ```

### Verifying Installation

- Run `pkg-config --libs --cflags sdl3` to check if SDL3 is correctly installed and accessible.
- Ensure your build system (e.g., Zig) can find SDL3 by linking with `-lSDL3`.

For detailed instructions or troubleshooting, visit the [SDL3 documentation](https://wiki.libsdl.org/SDL3/Installation).


## TODOs

### Version 0.1.0

- [x] Write a comprehensive set of keys in the event-manager component.
- [x] Implement parent-child relationship in objects.
- [x] Add Sprite drawable to the pre-defined drawables.
- [x] Add Text drawable to the pre-defined drawables.
- [ ] Make the object functionality extendable by integrating the LifeCycle within.
- [ ] Use rotations in draw logic of the current pre-defined drawables.
- [ ] Differentiate between absolute and relative positions and rotations.
- [ ] Add active state for object, and update only those who have active=true in the scene update method.
- [ ] Write remove methods for event-manager, and do cleanup, accordingly on scripts _end_ method.
- [ ] Write unit tests for all modules.


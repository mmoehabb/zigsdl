const c = @cImport({
    @cInclude("SDL2/SDL.h");
});

const Object = @import("./object.zig").Object;

pub const Scene = struct {
    objects: []*Object,

    pub fn update(self: *Scene, renderer: *c.SDL_Renderer) !void {
        for (self.objects) |obj| {
            try obj.draw(renderer);
        }
    }
};

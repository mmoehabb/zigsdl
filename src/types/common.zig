pub const Position = struct { x: f32, y: f32, z: f32 };

pub const Rotation = struct { x: f32, y: f32, z: f32 };

pub const Color = struct { r: usize, g: usize, b: usize, a: usize };

pub const LifeCycle = struct {
    preOpen: ?fn () void,
    postOpen: ?fn () void,
    preUpdate: ?fn () void,
    postUpdate: ?fn () void,
    preClose: ?fn () void,
    postClose: ?fn () void,
};

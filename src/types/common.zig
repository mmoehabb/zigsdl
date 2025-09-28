pub const Position = struct { x: f32, y: f32, z: f32 };

pub const Rotation = struct { x: f32, y: f32, z: f32 };

pub const Dimensions = struct { w: f32, h: f32, d: f32 };

pub const Color = struct { r: u8 = 0, g: u8 = 0, b: u8 = 0, a: u8 = 255 };

pub const LifeCycle = struct {
    preOpen: ?*fn () void,
    postOpen: ?*fn () void,
    preUpdate: ?*fn () void,
    postUpdate: ?*fn () void,
    preClose: ?*fn () void,
    postClose: ?*fn () void,
};

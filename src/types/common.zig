pub const Position = struct {
    x: f32,
    y: f32,
    z: f32,

    pub fn add(self: *Position, pos: Position) Position {
        return .{
            .x = self.x + pos.x,
            .y = self.y + pos.y,
            .z = self.z + pos.z,
        };
    }

    pub fn subtract(self: *Position, pos: Position) Position {
        return .{
            .x = self.x - pos.x,
            .y = self.y - pos.y,
            .z = self.z - pos.z,
        };
    }
};

pub const Rotation = struct {
    x: f32,
    y: f32,
    z: f32,

    pub fn add(self: *Rotation, rot: Rotation) Rotation {
        return .{
            .x = self.x + rot.x,
            .y = self.y + rot.y,
            .z = self.z + rot.z,
        };
    }

    pub fn subtract(self: *Rotation, rot: Rotation) Rotation {
        return .{
            .x = self.x - rot.x,
            .y = self.y - rot.y,
            .z = self.z - rot.z,
        };
    }
};

pub const Dimensions = struct {
    w: f32,
    h: f32,
    d: f32,

    pub fn scale(self: *Dimensions, s: f32) Dimensions {
        self.w *= s;
        self.h *= s;
        self.d *= s;
        return self.*;
    }
};

pub const Color = struct { r: u8 = 0, g: u8 = 0, b: u8 = 0, a: u8 = 255 };

pub const LifeCycle = struct {
    preOpen: ?*const fn (_: *anyopaque) void,
    postOpen: ?*const fn (_: *anyopaque) void,
    preUpdate: ?*const fn (_: *anyopaque) void,
    postUpdate: ?*const fn (_: *anyopaque) void,
    preClose: ?*const fn (_: *anyopaque) void,
    postClose: ?*const fn (_: *anyopaque) void,
};

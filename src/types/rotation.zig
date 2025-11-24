const Rotation = @This();

x: f32 = 0,
y: f32 = 0,
z: f32 = 0,

pub fn add(self: Rotation, rot: Rotation) Rotation {
    return .{
        .x = self.x + rot.x,
        .y = self.y + rot.y,
        .z = self.z + rot.z,
    };
}

pub fn subtract(self: Rotation, rot: Rotation) Rotation {
    return .{
        .x = self.x - rot.x,
        .y = self.y - rot.y,
        .z = self.z - rot.z,
    };
}

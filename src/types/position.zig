const Position = @This();

x: f32 = 0,
y: f32 = 0,
z: f32 = 0,

pub fn add(self: Position, pos: Position) Position {
    return .{
        .x = self.x + pos.x,
        .y = self.y + pos.y,
        .z = self.z + pos.z,
    };
}

pub fn subtract(self: Position, pos: Position) Position {
    return .{
        .x = self.x - pos.x,
        .y = self.y - pos.y,
        .z = self.z - pos.z,
    };
}

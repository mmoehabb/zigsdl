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

pub fn multiply(self: Position, operand: f32) Position {
    return .{
        .x = self.x * operand,
        .y = self.y * operand,
        .z = self.z * operand,
    };
}

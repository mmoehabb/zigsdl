// TODO: improve the performance of these methods by using zig vectors (SIMD).

const std = @import("std");
const Vector = @This();

x: f32 = 0,
y: f32 = 0,
z: f32 = 0,

pub fn add(self: Vector, pos: Vector) Vector {
    return .{
        .x = self.x + pos.x,
        .y = self.y + pos.y,
        .z = self.z + pos.z,
    };
}

pub fn subtract(self: Vector, pos: Vector) Vector {
    return .{
        .x = self.x - pos.x,
        .y = self.y - pos.y,
        .z = self.z - pos.z,
    };
}

pub fn multiply(self: Vector, operand: f32) Vector {
    return .{
        .x = self.x * operand,
        .y = self.y * operand,
        .z = self.z * operand,
    };
}

pub fn magnitude(self: Vector) f32 {
    const x = std.math.pow(f32, self.x, 2);
    const y = std.math.pow(f32, self.y, 2);
    const z = std.math.pow(f32, self.z, 2);
    return @sqrt(x + y + z);
}

pub fn abs(self: Vector) Vector {
    return .{
        .x = @abs(self.x),
        .y = @abs(self.y),
        .z = @abs(self.z),
    };
}

pub fn divide(self: Vector, p: Vector) Vector {
    return .{
        .x = if (p.x > 0) self.x / p.x else 0,
        .y = if (p.y > 0) self.y / p.y else 0,
        .z = if (p.z > 0) self.z / p.z else 0,
    };
}

pub fn floor(self: Vector) Vector {
    return .{
        .x = @floor(self.x),
        .y = @floor(self.y),
        .z = @floor(self.z),
    };
}

pub fn isEql(self: Vector, p: Vector) bool {
    return self.x == p.x and self.y == p.y and self.z == p.z;
}

pub fn evalAngleWith(self: Vector, v: Vector) f32 {
    const dot_product = (self.x * v.x) + (self.y * v.y) + (self.z * v.z);
    const self_mag = self.magnitude();
    const v_mag = v.magnitude();
    if (self_mag == 0.00 or v_mag == 0.00) return 0.00;

    var cos: f32 = dot_product / (self_mag * v_mag);
    cos = @max(-1.00, @min(1.00, cos));

    return std.math.acos(cos);
}

pub fn dot(self: Vector, v: Vector) f32 {
    return self.x * v.x + self.y * v.y + self.z * v.z;
}

pub fn lengthSq(self: Vector) f32 {
    return self.x * self.x + self.y * self.y + self.z * self.z;
}

pub fn normalize(self: Vector) Vector {
    const mag = self.magnitude();
    if (mag == 0) return .{};
    return self.multiply(1.0 / mag);
}

pub fn lerp(self: Vector, v: Vector, t: f32) Vector {
    return self.add(v.subtract(self).multiply(t));
}

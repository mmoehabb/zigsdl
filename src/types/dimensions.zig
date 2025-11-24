const Dimensions = @This();

w: f32,
h: f32,
d: f32,

pub fn scale(self: *Dimensions, s: f32) Dimensions {
    self.w *= s;
    self.h *= s;
    self.d *= s;
    return self.*;
}

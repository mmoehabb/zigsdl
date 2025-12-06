const Dimensions = @This();

w: f32 = 0.0,
h: f32 = 0.0,
d: f32 = 0.0,
scale: f32 = 1.0,

/// scale factor: is basically a calculated number out of the scales of
/// the parent (if exists) and the scene (if exists).
///
/// For example: the scale-factor of an object _o_ which is a child for parent _p_,
/// in scene _s_, whereas p.scale = 1.5 and s.scale = 1.25, equals 1.5 * 1.25.
sf: f32 = 1.0,

/// This should be used whenever the user wants to get a scaled version of the _Dimensions_.
pub fn getScaled(self: Dimensions) Dimensions {
    return .{
        .w = self.w * self.scale * self.sf,
        .h = self.h * self.scale * self.sf,
        .d = self.d * self.scale * self.sf,
    };
}

pub fn getAbsScale(self: Dimensions) f32 {
    return self.scale * self.sf;
}

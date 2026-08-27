//! A `Collision` struct defines a collision happened between object and an
//! arbitrary face in the space. It gets detected in the CollisionDetector.

const Face = @import("./face.zig");
const Vector = @import("./vector.zig");

pub const CPoint = struct {
    /// The point where collision happened/detected.
    point: Vector,

    /// Collision magnitude: the distance that the object needs to move
    /// in order to get out of the collision; represented in a vector from
    /// `.point` point to the closest point in `Collision.face`.
    mag: Vector,
};

const Collision = @This();

/// The face that the object collides with.
face: Face,

/// The objects face that collides with `.face`.
myface: Face,

/// Collision Point: a struct of the point where collision happened,
/// associated with collision magnitude values.
cps: [4]?CPoint = @splat(null),
_len: u3 = 0,

pub fn addPoint(self: *Collision, p: CPoint) void {
    if (self._len >= 4) return;
    self.cps[self._len] = p;
    self._len += 1;
}

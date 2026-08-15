//! A rectangular shape used for constructing the mesh.
//! NOTE: each point is located relative to the owner (object) position.
const std = @import("std");
const Vector = @import("./vector.zig");
const Object = @import("../modules/object.zig");

const Face = @This();

p1: Vector = .{},
p2: Vector = .{},
p3: Vector = .{},
p4: Vector = .{},
owner: *Object,

pub fn getCenter(self: Face) Vector {
    return self.p1
        .add(self.p2)
        .add(self.p3)
        .add(self.p4)
        .multiply(1 / 4);
}

pub fn add(self: Face, p: Vector) Face {
    return .{
        .p1 = self.p1.add(p),
        .p2 = self.p2.add(p),
        .p3 = self.p3.add(p),
        .p4 = self.p4.add(p),
        .owner = self.owner,
    };
}

pub fn subtract(self: Face, p: Vector) Face {
    return .{
        .p1 = self.p1.subtract(p),
        .p2 = self.p2.subtract(p),
        .p3 = self.p3.subtract(p),
        .p4 = self.p4.subtract(p),
        .owner = self.owner,
    };
}

/// Calculate and return the cirumference of the face.
pub fn calCircum(self: Face) f32 {
    const l1 = self.p2.subtract(self.p1).magnitude();
    const l2 = self.p3.subtract(self.p2).magnitude();
    const l3 = self.p4.subtract(self.p3).magnitude();
    const l4 = self.p1.subtract(self.p4).magnitude();
    return l1 + l2 + l3 + l4;
}

/// Return true if _p_ collides, or about to collides, the face.
pub fn isPCP(self: Face, p: Vector) bool {
    var mr = self.subtract(p);
    mr.p1 = mr.p1.divide(mr.p1.abs());
    mr.p2 = mr.p2.divide(mr.p2.abs());
    mr.p3 = mr.p3.divide(mr.p3.abs());
    mr.p4 = mr.p4.divide(mr.p4.abs());

    const v = mr.p1
        .add(mr.p2)
        .add(mr.p3)
        .add(mr.p4)
        .abs()
        .divide(.{ .x = 4, .y = 4, .z = 4 });

    return @floor(v.x) + @floor(v.y) + @floor(v.z) == 0;
}

pub fn closestVertexTo(self: Face, p: Vector) Vector {
    const l1 = self.p1.subtract(p).magnitude();
    const l2 = self.p2.subtract(p).magnitude();
    const l3 = self.p3.subtract(p).magnitude();
    const l4 = self.p4.subtract(p).magnitude();
    const m = @min(l1, l2, l3, l4);

    if (m == l1) return self.p1;
    if (m == l2) return self.p2;
    if (m == l3) return self.p3;
    if (m == l4) return self.p4;

    unreachable;
}

/// Return an alternative face where the face closest point to _p_ is
/// substituted with _p_.
pub fn getAlter(self: Face, p: Vector) Face {
    const closest = self.closestVertexTo(p);
    return self.replaceVertexWith(closest, p);
}

/// Return a cloned Face where _v_ is substituted with _p_.
pub fn replaceVertexWith(self: Face, v: Vector, p: Vector) Face {
    return .{
        .p1 = if (!v.isEql(self.p1)) self.p1 else p,
        .p2 = if (!v.isEql(self.p2)) self.p2 else p,
        .p3 = if (!v.isEql(self.p3)) self.p3 else p,
        .p4 = if (!v.isEql(self.p4)) self.p4 else p,
        .owner = self.owner,
    };
}

/// Returns true if point _p_ falls within (or on) the face.
pub fn contains(self: *Face, p: Vector) bool {
    const absFace = self.add(self.owner.position);
    if (!absFace.isPCP(p)) return false;
    const origCircum = absFace.calCircum();
    const altCircum = absFace.getAlter(p).calCircum();
    return altCircum <= origCircum;
}

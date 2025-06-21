pub const LifeCycle = struct {
    preOpen: ?fn () void,
    postOpen: ?fn () void,
    preUpdate: ?fn () void,
    postUpdate: ?fn () void,
    preClose: ?fn () void,
    postClose: ?fn () void,
};

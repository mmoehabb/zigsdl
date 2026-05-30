const std = @import("std");
const sdl = @import("../sdl.zig");

const AudioManager = @This();

_io: std.Io,
_io_thread: ?std.Thread = null,
_allocator: std.mem.Allocator,
_deinitialized: bool = false,

/// The audio streams retrieved from SDL_OpenAudioDeviceStream.
_audio_streams: std.ArrayList(*sdl.c.SDL_AudioStream) = std.ArrayList(*sdl.c.SDL_AudioStream).empty,

pub fn init(allocator: std.mem.Allocator, io: std.Io) !AudioManager {
    return AudioManager{
        ._io = io,
        ._allocator = allocator,
        ._audio_streams = std.ArrayList(*sdl.c.SDL_AudioStream).empty,
    };
}

pub fn addAudio(self: *AudioManager, audio_stream: *sdl.c.SDL_AudioStream) !void {
    if (self._audio_streams.items.len == 0) {
        self._io_thread = std.Thread.spawn(.{}, invokeCleanCycle, .{self}) catch |e| return e;
    }
    try self._audio_streams.append(self._allocator, audio_stream);
}

pub fn deinit(self: *AudioManager) void {
    self._deinitialized = true;
    if (self._io_thread) |thread| thread.join();
    self._audio_streams.deinit(self._allocator);
}

fn invokeCleanCycle(self: *AudioManager) void {
    var f = self._io.async(cleanCycle, .{self});
    f.await(self._io);
    if (!self._deinitialized) return self.invokeCleanCycle();
}

fn cleanCycle(self: *AudioManager) void {
    self._io.sleep(.fromSeconds(1), .awake) catch {
        std.log.err("audio-player: Io Sleep Failed!", .{});
        for (self._audio_streams.items) |stream| sdl.c.SDL_DestroyAudioStream(stream);
        for (self._audio_streams.items, 0..) |_, i| _ = self._audio_streams.orderedRemove(i);
        return;
    };
    if (self._deinitialized) return;

    var indexes: [100]usize = undefined; // TODO: audit
    var cursor: usize = 0;
    for (self._audio_streams.items, 0..) |stream, i| {
        if (sdl.c.SDL_GetAudioStreamAvailable(stream) > 0) continue;
        sdl.c.SDL_DestroyAudioStream(stream);
        indexes[cursor] = i;
        cursor += 1;
    }
    self._audio_streams.orderedRemoveMany(indexes[0..cursor]);
}

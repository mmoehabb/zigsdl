const std = @import("std");
const sdl = @import("../sdl.zig");
const AudioStream = @import("./audio-stream.zig");

const AudioManager = @This();

_io: std.Io,
_io_thread: ?std.Thread = null,
_allocator: std.mem.Allocator,
_deinitialized: bool = false,

/// The audio streams retrieved from SDL_OpenAudioDeviceStream.
_audio_streams: std.ArrayList(AudioStream) = std.ArrayList(AudioStream).empty,

pub fn init(allocator: std.mem.Allocator, io: std.Io) !AudioManager {
    return AudioManager{
        ._io = io,
        ._allocator = allocator,
        ._audio_streams = std.ArrayList(AudioStream).empty,
    };
}

pub fn deinit(self: *AudioManager) void {
    self._deinitialized = true;
    if (self._io_thread) |thread| thread.join();
    self._audio_streams.deinit(self._allocator);
}

/// This creates a new (paused, by default) audio stream and return it for the user to use.
/// Users shall only get this stream when they need it; push audio data
/// into it immediately. As this stream will be auto destroyed soon,
/// by the clean cycle, if it's found empty and not paused.
pub fn newStream(self: *AudioManager, audio_spec: *sdl.c.SDL_AudioSpec) !AudioStream {
    const audioStream = try AudioStream.new(audio_spec);
    if (self._audio_streams.items.len == 0) {
        self._io_thread = std.Thread.spawn(.{}, invokeCleanCycle, .{self}) catch |e| return e;
    }
    try self._audio_streams.append(self._allocator, audioStream);
    return audioStream;
}

fn invokeCleanCycle(self: *AudioManager) void {
    var f = self._io.async(cleanCycle, .{self});
    f.await(self._io);
    if (!self._deinitialized) return self.invokeCleanCycle();
}

/// Loop over the current audio streams and destroy the unused ones;
/// the ones with no audio data avaiable nor paused.
fn cleanCycle(self: *AudioManager) void {
    self._io.sleep(.fromSeconds(1), .awake) catch {
        std.log.err("audio-player: Io Sleep Failed!", .{});
        for (self._audio_streams.items) |stream| stream.destroy();
        for (self._audio_streams.items, 0..) |_, i| _ = self._audio_streams.orderedRemove(i);
        return;
    };
    if (self._deinitialized) return;

    var indexes: [100]usize = undefined; // TODO: audit
    var cursor: usize = 0;
    for (self._audio_streams.items, 0..) |stream, i| {
        if (stream.isPaused()) continue;
        if (stream.isPlayingAudio()) continue;
        stream.destroy();
        indexes[cursor] = i;
        cursor += 1;
    }
    self._audio_streams.orderedRemoveMany(indexes[0..cursor]);
}

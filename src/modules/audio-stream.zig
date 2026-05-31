const std = @import("std");
const sdl = @import("../sdl.zig");

const AudioStream = @This();

_stream: ?*sdl.c.SDL_AudioStream = null,

pub fn new(audio_spec: *sdl.c.SDL_AudioSpec) !AudioStream {
    if (sdl.c.SDL_OpenAudioDeviceStream(
        sdl.c.SDL_AUDIO_DEVICE_DEFAULT_PLAYBACK,
        audio_spec,
        null,
        null,
    )) |stream| {
        return AudioStream{
            ._stream = stream,
        };
    } else {
        return error.NewStreamFailed;
    }
}

pub fn destroy(self: *const AudioStream) void {
    sdl.c.SDL_DestroyAudioStream(self._stream);
}

pub fn putAudio(self: *const AudioStream, buf: [*c]u8, len: usize) void {
    if (!sdl.c.SDL_PutAudioStreamData(
        self._stream,
        buf,
        @as(c_int, @intCast(len)),
    )) {
        std.log.err("AudioStream: {s}\n", .{sdl.c.SDL_GetError()});
        return;
    }
}

pub fn isPaused(self: *const AudioStream) bool {
    return sdl.c.SDL_AudioStreamDevicePaused(self._stream);
}

pub fn isPlayingAudio(self: *const AudioStream) bool {
    return sdl.c.SDL_GetAudioStreamAvailable(self._stream) > 0;
}

pub fn pause(self: *const AudioStream) void {
    if (!sdl.c.SDL_PauseAudioStreamDevice(self._audio_stream)) {
        std.log.warn("AudioPlayer: {s}", .{sdl.c.SDL_GetError()});
    }
}

pub fn @"resume"(self: *const AudioStream) void {
    if (!sdl.c.SDL_ResumeAudioStreamDevice(self._stream)) {
        std.log.warn("AudioPlayer: {s}", .{sdl.c.SDL_GetError()});
    }
}

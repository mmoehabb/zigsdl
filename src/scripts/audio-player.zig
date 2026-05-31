//! Loads and plays WAV files by using SDL as documented here:
//! [https://wiki.libsdl.org/SDL3/CategoryAudio](https://wiki.libsdl.org/SDL3/CategoryAudio).

const std = @import("std");
const sdl = @import("../sdl.zig");
const modules = @import("../modules/mod.zig");
const types = @import("../types/mod.zig");

const AudioPlayer = @This();

wav_path: []const u8,

/// Set it to true before invoking _play_, in order to play the audio_buf recursively.
loop: bool = false,

/// The volume of the audio to be played. Volume values range between 0.0 and 1.0.
_volume: f32 = 1.0,

/// Audio file specifications like: number of channels, format, and frequency.
/// It gets loaded by SDL_LoadWAV function.
_audio_spec: sdl.c.SDL_AudioSpec = sdl.c.SDL_AudioSpec{},

/// The audio stream buffer; it gets loaded by SDL_LoadWAV function.
_audio_buf: [*c]u8 = null,

/// The audio stream buffer length; it gets loaded by SDL_LoadWAV function.
_audio_buf_len: u32 = 0,

/// The audio duration in seconds. It's calculated according to the spec and buf_len, as follows:
/// ```zig
/// const sample_size = SDL_AUDIO_BITSIZE(self._audio_spec.format) / 8;
/// const total_samples = self._audio_buf_len / sample_size;
/// const sample_per_channel = total_samples / @as(u32, @intCast(self._audio_spec.channels));
/// const dur = sample_per_channel / @as(u32, @intCast(self._audio_spec.freq));
/// ```
_audio_dur: u32 = 0,

_script_strategy: modules.ScriptStrategy = modules.ScriptStrategy{
    .start = start,
    .update = update,
    .end = end,
},

_end_invoked: bool = false,

pub fn toScript(self: *AudioPlayer) modules.Script {
    return modules.Script{
        .name = "AudioPlayer",
        .strategy = &self._script_strategy,
    };
}

pub fn loadWAV(self: *AudioPlayer, path: []const u8) void {
    self.wav_path = path;
    if (!sdl.c.SDL_LoadWAV(
        self.wav_path.ptr,
        &self._audio_spec,
        &self._audio_buf,
        &self._audio_buf_len,
    )) {
        std.log.err("{s}\n", .{sdl.c.SDL_GetError()});
        return;
    }
    self._audio_dur = self.getAudioDur();
}

pub fn play(self: *AudioPlayer) !modules.AudioStream {
    var audio_stream = try modules.Globals.audioManager.?.newStream(&self._audio_spec);
    audio_stream.@"resume"(); // NOTE: streams are paused by default
    audio_stream.putAudio(self._audio_buf, self._audio_buf_len);
    return audio_stream;
}

/// 1.0 volume is equivalent to 100%.
pub fn setVolume(self: *AudioPlayer, volume: f32) void {
    if (!sdl.c.SDL_MixAudio(
        self._audio_buf,
        self._audio_buf,
        self._audio_spec.format,
        self._audio_buf_len,
        volume - self._volume,
    )) std.log.warn("AudioPlayer: {s}\n", .{sdl.c.SDL_GetError()});
    self._volume = volume;
}

fn start(s: *modules.Script, _: *modules.Object) void {
    const self = @as(
        *AudioPlayer,
        @constCast(@fieldParentPtr("_script_strategy", s.strategy)),
    );

    if (!sdl.c.SDL_LoadWAV(
        self.wav_path.ptr,
        &self._audio_spec,
        &self._audio_buf,
        &self._audio_buf_len,
    )) {
        std.log.err("{s}\n", .{sdl.c.SDL_GetError()});
        return;
    }

    self._audio_dur = self.getAudioDur();
}

fn update(_: *modules.Script, _: *modules.Object) void {}

fn end(s: *modules.Script, _: *modules.Object) void {
    const self = @as(
        *AudioPlayer,
        @constCast(@fieldParentPtr("_script_strategy", s.strategy)),
    );
    sdl.c.SDL_free(self._audio_buf);
}

fn getAudioDur(self: *AudioPlayer) u32 {
    const sample_size = sdl.c.SDL_AUDIO_BITSIZE(self._audio_spec.format) / 8;
    const total_samples = self._audio_buf_len / sample_size;
    const sample_per_channel = total_samples / @as(u32, @intCast(self._audio_spec.channels));
    return sample_per_channel / @as(u32, @intCast(self._audio_spec.freq));
}

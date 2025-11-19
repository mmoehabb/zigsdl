const std = @import("std");
const sdl = @import("../sdl.zig");
const modules = @import("../modules/mod.zig");
const types = @import("../types/mod.zig");

pub const AudioPlayer = struct {
    wav_path: []const u8,

    _audio_spec: sdl.c.SDL_AudioSpec = sdl.c.SDL_AudioSpec{},
    _audio_buf: [*c]u8 = null,
    _audio_buf_len: u32 = 0,
    _audio_dur: u32 = 0,

    _script_strategy: modules.ScriptStrategy = modules.ScriptStrategy{
        .start = start,
        .update = update,
        .end = end,
    },

    pub fn toScript(self: *AudioPlayer) modules.Script {
        return modules.Script{
            .name = "AudioPlayer",
            .strategy = &self._script_strategy,
        };
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

    pub fn play(self: *AudioPlayer) void {
        const stream = sdl.c.SDL_OpenAudioDeviceStream(
            sdl.c.SDL_AUDIO_DEVICE_DEFAULT_PLAYBACK,
            &self._audio_spec,
            null,
            null,
        );

        if (!sdl.c.SDL_PutAudioStreamData(
            stream,
            self._audio_buf,
            @as(c_int, @intCast(self._audio_buf_len)),
        )) {
            std.log.err("{s}\n", .{sdl.c.SDL_GetError()});
            return;
        }

        // NOTE: streams are paused by default
        if (!sdl.c.SDL_ResumeAudioStreamDevice(stream)) {
            std.log.err("{s}\n", .{sdl.c.SDL_GetError()});
            return;
        }

        // Destroy the audio-stream after the audio duration is passed.
        const err = std.Thread.spawn(.{}, destroyAudioStream, .{ stream, self._audio_dur });
        if (err == error.SpawnError) sdl.c.SDL_DestroyAudioStream(stream);
    }

    fn getAudioDur(self: *AudioPlayer) u32 {
        const sample_size = sdl.c.SDL_AUDIO_BITSIZE(self._audio_spec.format) / 8;
        const total_samples = self._audio_buf_len / sample_size;
        const sample_per_channel = total_samples / @as(u32, @intCast(self._audio_spec.channels));
        return sample_per_channel / @as(u32, @intCast(self._audio_spec.freq));
    }

    fn destroyAudioStream(stream: ?*sdl.c.SDL_AudioStream, delay: u32) void {
        std.Thread.sleep(delay * 1_000_000_000);
        sdl.c.SDL_DestroyAudioStream(stream);
    }
};

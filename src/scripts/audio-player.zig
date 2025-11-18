const std = @import("std");
const sdl = @import("../sdl.zig");
const modules = @import("../modules/mod.zig");
const types = @import("../types/mod.zig");

pub const AudioPlayer = struct {
    wav_path: []const u8,

    _stream: ?*sdl.c.SDL_AudioStream = null,
    _audio_buf: [*c]u8 = null,
    _audio_buf_len: u32 = 0,

    _script_strategy: modules.ScriptStrategy = modules.ScriptStrategy{
        .start = start,
        .update = update,
        .end = end,
    },

    pub fn toScript(self: *AudioPlayer) modules.Script {
        return modules.Script{ .strategy = &self._script_strategy };
    }

    fn start(s: *modules.Script, _: *modules.Object) void {
        const self = @as(
            *AudioPlayer,
            @constCast(@fieldParentPtr("_script_strategy", s.strategy)),
        );

        // Load file buffer
        var spec = sdl.c.SDL_AudioSpec{};
        if (!sdl.c.SDL_LoadWAV(
            self.wav_path.ptr,
            &spec,
            &self._audio_buf,
            &self._audio_buf_len,
        )) {
            std.log.err("{s}\n", .{sdl.c.SDL_GetError()});
            return;
        }

        // Get default playback device stream
        self._stream = sdl.c.SDL_OpenAudioDeviceStream(
            sdl.c.SDL_AUDIO_DEVICE_DEFAULT_PLAYBACK,
            &spec,
            null,
            null,
        );

        // NOTE: streams are paused by default
        if (!sdl.c.SDL_ResumeAudioStreamDevice(self._stream)) {
            std.log.err("{s}\n", .{sdl.c.SDL_GetError()});
            return;
        }
    }

    fn update(_: *modules.Script, _: *modules.Object) void {}

    fn end(s: *modules.Script, _: *modules.Object) void {
        const self = @as(
            *AudioPlayer,
            @constCast(@fieldParentPtr("_script_strategy", s.strategy)),
        );
        sdl.c.SDL_free(self._audio_buf);
        sdl.c.SDL_DestroyAudioStream(self._stream);
    }

    pub fn play(self: *AudioPlayer) void {
        if (!sdl.c.SDL_PutAudioStreamData(
            self._stream,
            self._audio_buf,
            @as(c_int, @intCast(self._audio_buf_len)),
        )) {
            std.log.err("{s}\n", .{sdl.c.SDL_GetError()});
            return;
        }
    }
};

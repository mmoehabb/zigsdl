const std = @import("std");
const sdl = @import("../sdl.zig");

const Key = @import("../types/event.zig").Key;
const KeyState = @import("../types/event.zig").KeyState;

pub const EventManager = struct {
    keys: std.AutoHashMap(Key, KeyState) = std.AutoHashMap(Key, KeyState).init(std.heap.page_allocator),

    pub fn deinit(self: *EventManager) void {
        self.keys.deinit();
    }

    pub fn getKeys(self: *EventManager) std.AutoHashMap(Key, KeyState) {
        return self.keys;
    }

    pub fn isKeyDown(self: *EventManager, key: Key) bool {
        const state = self.keys.get(key) orelse .Up;
        return state == .Down;
    }

    pub fn isKeyUp(self: *EventManager, key: Key) bool {
        const state = self.keys.get(key) orelse .Down;
        return state == .Up;
    }

    pub fn invokeEventLoop(self: *EventManager) !sdl.c.SDL_Event {
        var event: sdl.c.SDL_Event = undefined;
        while (sdl.c.SDL_PollEvent(&event)) {
            switch (event.type) {
                sdl.c.SDL_EVENT_KEY_DOWN => {
                    const key = scancodeToKey(event.key.scancode);
                    try self.keyDown(key);
                },
                sdl.c.SDL_EVENT_KEY_UP => {
                    const key = scancodeToKey(event.key.scancode);
                    try self.keyUp(key);
                },
                sdl.c.SDL_EVENT_MOUSE_BUTTON_DOWN => {
                    const key = mouseCodeToEnum(event.key.scancode);
                    try self.keyDown(key);
                },
                sdl.c.SDL_EVENT_MOUSE_BUTTON_UP => {
                    const key = mouseCodeToEnum(event.key.scancode);
                    try self.keyUp(key);
                },
                else => return event,
            }
        }
        return event;
    }

    fn keyDown(self: *EventManager, key: Key) !void {
        try self.keys.put(key, .Down);
    }

    fn keyUp(self: *EventManager, key: Key) !void {
        try self.keys.put(key, .Up);
    }

    fn scancodeToKey(scancode: sdl.c.SDL_Scancode) Key {
        return switch (scancode) {
            sdl.c.SDL_SCANCODE_UNKNOWN => .Unknown,
            sdl.c.SDL_SCANCODE_A => .A,
            sdl.c.SDL_SCANCODE_B => .B,
            sdl.c.SDL_SCANCODE_C => .C,
            sdl.c.SDL_SCANCODE_D => .D,
            sdl.c.SDL_SCANCODE_E => .E,
            sdl.c.SDL_SCANCODE_F => .F,
            sdl.c.SDL_SCANCODE_G => .G,
            sdl.c.SDL_SCANCODE_H => .H,
            sdl.c.SDL_SCANCODE_I => .I,
            sdl.c.SDL_SCANCODE_J => .J,
            sdl.c.SDL_SCANCODE_K => .K,
            sdl.c.SDL_SCANCODE_L => .L,
            sdl.c.SDL_SCANCODE_M => .M,
            sdl.c.SDL_SCANCODE_N => .N,
            sdl.c.SDL_SCANCODE_O => .O,
            sdl.c.SDL_SCANCODE_P => .P,
            sdl.c.SDL_SCANCODE_Q => .Q,
            sdl.c.SDL_SCANCODE_R => .R,
            sdl.c.SDL_SCANCODE_S => .S,
            sdl.c.SDL_SCANCODE_T => .T,
            sdl.c.SDL_SCANCODE_U => .U,
            sdl.c.SDL_SCANCODE_V => .V,
            sdl.c.SDL_SCANCODE_W => .W,
            sdl.c.SDL_SCANCODE_X => .X,
            sdl.c.SDL_SCANCODE_Y => .Y,
            sdl.c.SDL_SCANCODE_Z => .Z,
            sdl.c.SDL_SCANCODE_0 => .Num0,
            sdl.c.SDL_SCANCODE_1 => .Num1,
            sdl.c.SDL_SCANCODE_2 => .Num2,
            sdl.c.SDL_SCANCODE_3 => .Num3,
            sdl.c.SDL_SCANCODE_4 => .Num4,
            sdl.c.SDL_SCANCODE_5 => .Num5,
            sdl.c.SDL_SCANCODE_6 => .Num6,
            sdl.c.SDL_SCANCODE_7 => .Num7,
            sdl.c.SDL_SCANCODE_8 => .Num8,
            sdl.c.SDL_SCANCODE_9 => .Num9,
            sdl.c.SDL_SCANCODE_RETURN => .Return,
            sdl.c.SDL_SCANCODE_ESCAPE => .Escape,
            sdl.c.SDL_SCANCODE_BACKSPACE => .Backspace,
            sdl.c.SDL_SCANCODE_TAB => .Tab,
            sdl.c.SDL_SCANCODE_SPACE => .Space,
            sdl.c.SDL_SCANCODE_MINUS => .Minus,
            sdl.c.SDL_SCANCODE_EQUALS => .Equals,
            sdl.c.SDL_SCANCODE_LEFTBRACKET => .LeftBracket,
            sdl.c.SDL_SCANCODE_RIGHTBRACKET => .RightBracket,
            sdl.c.SDL_SCANCODE_BACKSLASH => .Backslash,
            sdl.c.SDL_SCANCODE_NONUSHASH => .NonUsHash,
            sdl.c.SDL_SCANCODE_SEMICOLON => .Semicolon,
            sdl.c.SDL_SCANCODE_APOSTROPHE => .Apostrophe,
            sdl.c.SDL_SCANCODE_GRAVE => .Grave,
            sdl.c.SDL_SCANCODE_COMMA => .Comma,
            sdl.c.SDL_SCANCODE_PERIOD => .Period,
            sdl.c.SDL_SCANCODE_SLASH => .Slash,
            sdl.c.SDL_SCANCODE_CAPSLOCK => .CapsLock,
            sdl.c.SDL_SCANCODE_F1 => .F1,
            sdl.c.SDL_SCANCODE_F2 => .F2,
            sdl.c.SDL_SCANCODE_F3 => .F3,
            sdl.c.SDL_SCANCODE_F4 => .F4,
            sdl.c.SDL_SCANCODE_F5 => .F5,
            sdl.c.SDL_SCANCODE_F6 => .F6,
            sdl.c.SDL_SCANCODE_F7 => .F7,
            sdl.c.SDL_SCANCODE_F8 => .F8,
            sdl.c.SDL_SCANCODE_F9 => .F9,
            sdl.c.SDL_SCANCODE_F10 => .F10,
            sdl.c.SDL_SCANCODE_F11 => .F11,
            sdl.c.SDL_SCANCODE_F12 => .F12,
            sdl.c.SDL_SCANCODE_PRINTSCREEN => .PrintScreen,
            sdl.c.SDL_SCANCODE_SCROLLLOCK => .ScrollLock,
            sdl.c.SDL_SCANCODE_PAUSE => .Pause,
            sdl.c.SDL_SCANCODE_INSERT => .Insert,
            sdl.c.SDL_SCANCODE_HOME => .Home,
            sdl.c.SDL_SCANCODE_PAGEUP => .PageUp,
            sdl.c.SDL_SCANCODE_DELETE => .Delete,
            sdl.c.SDL_SCANCODE_END => .End,
            sdl.c.SDL_SCANCODE_PAGEDOWN => .PageDown,
            sdl.c.SDL_SCANCODE_RIGHT => .Right,
            sdl.c.SDL_SCANCODE_LEFT => .Left,
            sdl.c.SDL_SCANCODE_DOWN => .Down,
            sdl.c.SDL_SCANCODE_UP => .Up,
            sdl.c.SDL_SCANCODE_NUMLOCKCLEAR => .NumLockClear,
            sdl.c.SDL_SCANCODE_KP_DIVIDE => .KpDivide,
            sdl.c.SDL_SCANCODE_KP_MULTIPLY => .KpMultiply,
            sdl.c.SDL_SCANCODE_KP_MINUS => .KpMinus,
            sdl.c.SDL_SCANCODE_KP_PLUS => .KpPlus,
            sdl.c.SDL_SCANCODE_KP_ENTER => .KpEnter,
            sdl.c.SDL_SCANCODE_KP_1 => .Kp1,
            sdl.c.SDL_SCANCODE_KP_2 => .Kp2,
            sdl.c.SDL_SCANCODE_KP_3 => .Kp3,
            sdl.c.SDL_SCANCODE_KP_4 => .Kp4,
            sdl.c.SDL_SCANCODE_KP_5 => .Kp5,
            sdl.c.SDL_SCANCODE_KP_6 => .Kp6,
            sdl.c.SDL_SCANCODE_KP_7 => .Kp7,
            sdl.c.SDL_SCANCODE_KP_8 => .Kp8,
            sdl.c.SDL_SCANCODE_KP_9 => .Kp9,
            sdl.c.SDL_SCANCODE_KP_0 => .Kp0,
            sdl.c.SDL_SCANCODE_KP_PERIOD => .KpPeriod,
            sdl.c.SDL_SCANCODE_NONUSBACKSLASH => .NonUsBackslash,
            sdl.c.SDL_SCANCODE_APPLICATION => .Application,
            sdl.c.SDL_SCANCODE_POWER => .Power,
            sdl.c.SDL_SCANCODE_KP_EQUALS => .KpEquals,
            sdl.c.SDL_SCANCODE_F13 => .F13,
            sdl.c.SDL_SCANCODE_F14 => .F14,
            sdl.c.SDL_SCANCODE_F15 => .F15,
            sdl.c.SDL_SCANCODE_F16 => .F16,
            sdl.c.SDL_SCANCODE_F17 => .F17,
            sdl.c.SDL_SCANCODE_F18 => .F18,
            sdl.c.SDL_SCANCODE_F19 => .F19,
            sdl.c.SDL_SCANCODE_F20 => .F20,
            sdl.c.SDL_SCANCODE_F21 => .F21,
            sdl.c.SDL_SCANCODE_F22 => .F22,
            sdl.c.SDL_SCANCODE_F23 => .F23,
            sdl.c.SDL_SCANCODE_F24 => .F24,
            sdl.c.SDL_SCANCODE_EXECUTE => .Execute,
            sdl.c.SDL_SCANCODE_HELP => .Help,
            sdl.c.SDL_SCANCODE_MENU => .Menu,
            sdl.c.SDL_SCANCODE_SELECT => .Select,
            sdl.c.SDL_SCANCODE_STOP => .Stop,
            sdl.c.SDL_SCANCODE_AGAIN => .Again,
            sdl.c.SDL_SCANCODE_UNDO => .Undo,
            sdl.c.SDL_SCANCODE_CUT => .Cut,
            sdl.c.SDL_SCANCODE_COPY => .Copy,
            sdl.c.SDL_SCANCODE_PASTE => .Paste,
            sdl.c.SDL_SCANCODE_FIND => .Find,
            sdl.c.SDL_SCANCODE_MUTE => .Mute,
            sdl.c.SDL_SCANCODE_VOLUMEUP => .VolumeUp,
            sdl.c.SDL_SCANCODE_VOLUMEDOWN => .VolumeDown,
            sdl.c.SDL_SCANCODE_KP_COMMA => .KpComma,
            sdl.c.SDL_SCANCODE_KP_EQUALSAS400 => .KpEqualsAS400,
            sdl.c.SDL_SCANCODE_INTERNATIONAL1 => .International1,
            sdl.c.SDL_SCANCODE_INTERNATIONAL2 => .International2,
            sdl.c.SDL_SCANCODE_INTERNATIONAL3 => .International3,
            sdl.c.SDL_SCANCODE_INTERNATIONAL4 => .International4,
            sdl.c.SDL_SCANCODE_INTERNATIONAL5 => .International5,
            sdl.c.SDL_SCANCODE_INTERNATIONAL6 => .International6,
            sdl.c.SDL_SCANCODE_INTERNATIONAL7 => .International7,
            sdl.c.SDL_SCANCODE_INTERNATIONAL8 => .International8,
            sdl.c.SDL_SCANCODE_INTERNATIONAL9 => .International9,
            sdl.c.SDL_SCANCODE_LANG1 => .Lang1,
            sdl.c.SDL_SCANCODE_LANG2 => .Lang2,
            sdl.c.SDL_SCANCODE_LANG3 => .Lang3,
            sdl.c.SDL_SCANCODE_LANG4 => .Lang4,
            sdl.c.SDL_SCANCODE_LANG5 => .Lang5,
            sdl.c.SDL_SCANCODE_LANG6 => .Lang6,
            sdl.c.SDL_SCANCODE_LANG7 => .Lang7,
            sdl.c.SDL_SCANCODE_LANG8 => .Lang8,
            sdl.c.SDL_SCANCODE_LANG9 => .Lang9,
            sdl.c.SDL_SCANCODE_ALTERASE => .AltErase,
            sdl.c.SDL_SCANCODE_SYSREQ => .SysReq,
            sdl.c.SDL_SCANCODE_CANCEL => .Cancel,
            sdl.c.SDL_SCANCODE_CLEAR => .Clear,
            sdl.c.SDL_SCANCODE_PRIOR => .Prior,
            sdl.c.SDL_SCANCODE_RETURN2 => .Return2,
            sdl.c.SDL_SCANCODE_SEPARATOR => .Separator,
            sdl.c.SDL_SCANCODE_OUT => .Out,
            sdl.c.SDL_SCANCODE_OPER => .Oper,
            sdl.c.SDL_SCANCODE_CLEARAGAIN => .ClearAgain,
            sdl.c.SDL_SCANCODE_CRSEL => .CrSel,
            sdl.c.SDL_SCANCODE_EXSEL => .ExSel,
            sdl.c.SDL_SCANCODE_KP_00 => .Kp00,
            sdl.c.SDL_SCANCODE_KP_000 => .Kp000,
            sdl.c.SDL_SCANCODE_THOUSANDSSEPARATOR => .ThousandsSeparator,
            sdl.c.SDL_SCANCODE_DECIMALSEPARATOR => .DecimalSeparator,
            sdl.c.SDL_SCANCODE_CURRENCYUNIT => .CurrencyUnit,
            sdl.c.SDL_SCANCODE_CURRENCYSUBUNIT => .CurrencySubUnit,
            sdl.c.SDL_SCANCODE_KP_LEFTPAREN => .KpLeftParen,
            sdl.c.SDL_SCANCODE_KP_RIGHTPAREN => .KpRightParen,
            sdl.c.SDL_SCANCODE_KP_LEFTBRACE => .KpLeftBrace,
            sdl.c.SDL_SCANCODE_KP_RIGHTBRACE => .KpRightBrace,
            sdl.c.SDL_SCANCODE_KP_TAB => .KpTab,
            sdl.c.SDL_SCANCODE_KP_BACKSPACE => .KpBackspace,
            sdl.c.SDL_SCANCODE_KP_A => .KpA,
            sdl.c.SDL_SCANCODE_KP_B => .KpB,
            sdl.c.SDL_SCANCODE_KP_C => .KpC,
            sdl.c.SDL_SCANCODE_KP_D => .KpD,
            sdl.c.SDL_SCANCODE_KP_E => .KpE,
            sdl.c.SDL_SCANCODE_KP_F => .KpF,
            sdl.c.SDL_SCANCODE_KP_XOR => .KpXor,
            sdl.c.SDL_SCANCODE_KP_POWER => .KpPower,
            sdl.c.SDL_SCANCODE_KP_PERCENT => .KpPercent,
            sdl.c.SDL_SCANCODE_KP_LESS => .KpLess,
            sdl.c.SDL_SCANCODE_KP_GREATER => .KpGreater,
            sdl.c.SDL_SCANCODE_KP_AMPERSAND => .KpAmpersand,
            sdl.c.SDL_SCANCODE_KP_DBLAMPERSAND => .KpDblAmpersand,
            sdl.c.SDL_SCANCODE_KP_VERTICALBAR => .KpVerticalBar,
            sdl.c.SDL_SCANCODE_KP_DBLVERTICALBAR => .KpDblVerticalBar,
            sdl.c.SDL_SCANCODE_KP_COLON => .KpColon,
            sdl.c.SDL_SCANCODE_KP_HASH => .KpHash,
            sdl.c.SDL_SCANCODE_KP_SPACE => .KpSpace,
            sdl.c.SDL_SCANCODE_KP_AT => .KpAt,
            sdl.c.SDL_SCANCODE_KP_EXCLAM => .KpExclam,
            sdl.c.SDL_SCANCODE_KP_MEMSTORE => .KpMemStore,
            sdl.c.SDL_SCANCODE_KP_MEMRECALL => .KpMemRecall,
            sdl.c.SDL_SCANCODE_KP_MEMCLEAR => .KpMemClear,
            sdl.c.SDL_SCANCODE_KP_MEMADD => .KpMemAdd,
            sdl.c.SDL_SCANCODE_KP_MEMSUBTRACT => .KpMemSubtract,
            sdl.c.SDL_SCANCODE_KP_MEMMULTIPLY => .KpMemMultiply,
            sdl.c.SDL_SCANCODE_KP_MEMDIVIDE => .KpMemDivide,
            sdl.c.SDL_SCANCODE_KP_PLUSMINUS => .KpPlusMinus,
            sdl.c.SDL_SCANCODE_KP_CLEAR => .KpClear,
            sdl.c.SDL_SCANCODE_KP_CLEARENTRY => .KpClearEntry,
            sdl.c.SDL_SCANCODE_KP_BINARY => .KpBinary,
            sdl.c.SDL_SCANCODE_KP_OCTAL => .KpOctal,
            sdl.c.SDL_SCANCODE_KP_DECIMAL => .KpDecimal,
            sdl.c.SDL_SCANCODE_KP_HEXADECIMAL => .KpHexadecimal,
            sdl.c.SDL_SCANCODE_LCTRL => .LCtrl,
            sdl.c.SDL_SCANCODE_LSHIFT => .LShift,
            sdl.c.SDL_SCANCODE_LALT => .LAlt,
            sdl.c.SDL_SCANCODE_LGUI => .LGui,
            sdl.c.SDL_SCANCODE_RCTRL => .RCtrl,
            sdl.c.SDL_SCANCODE_RSHIFT => .RShift,
            sdl.c.SDL_SCANCODE_RALT => .RAlt,
            sdl.c.SDL_SCANCODE_RGUI => .RGui,
            sdl.c.SDL_SCANCODE_MODE => .Mode,
            sdl.c.SDL_SCANCODE_AC_SEARCH => .AcSearch,
            sdl.c.SDL_SCANCODE_AC_HOME => .AcHome,
            sdl.c.SDL_SCANCODE_AC_BACK => .AcBack,
            sdl.c.SDL_SCANCODE_AC_FORWARD => .AcForward,
            sdl.c.SDL_SCANCODE_AC_STOP => .AcStop,
            sdl.c.SDL_SCANCODE_AC_REFRESH => .AcRefresh,
            sdl.c.SDL_SCANCODE_AC_BOOKMARKS => .AcBookmarks,
            else => .Unknown,
        };
    }

    fn mouseCodeToEnum(scancode: sdl.c.SDL_Scancode) Key {
        return switch (scancode) {
            sdl.c.SDL_BUTTON_LEFT => .LeftMouse,
            sdl.c.SDL_BUTTON_MIDDLE => .MiddleMouse,
            sdl.c.SDL_BUTTON_RIGHT => .RightMouse,
            sdl.c.SDL_BUTTON_X1 => .X1Mouse,
            sdl.c.SDL_BUTTON_X2 => .X2Mouse,
            else => .LeftMouse, // NOTE: any unknown mouse click event considered as a left click
        };
    }
};

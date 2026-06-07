const zigsdl = @import("zigsdl");
const std = @import("std");

const font_path = "./examples/assets/OpenSans-Regular.ttf";
const font_size: f32 = 18;

const color_options = [_][]const u8{ "Red", "Green", "Blue", "Yellow", "Purple" };

var g_status: *zigsdl.drawables.Text = undefined;
var g_button_clicks: u32 = 0;
var g_checkbox: *zigsdl.drawables.CheckBox = undefined;
var g_text_input: *zigsdl.drawables.TextInput = undefined;
var g_select: *zigsdl.drawables.Select = undefined;

fn onButtonClick(_: *zigsdl.drawables.Button) void {
    g_button_clicks += 1;
    g_status.setLabel("Button clicked!");
}

fn onToggle(self: *zigsdl.drawables.CheckBox) void {
    _ = self;
    g_status.setLabel(if (g_checkbox.checked) "Checkbox: ON" else "Checkbox: OFF");
}

fn onTextChange(self: *zigsdl.drawables.TextInput) void {
    g_status.setLabel(self.getText());
}

fn onSelectChange(self: *zigsdl.drawables.Select) void {
    if (self.getSelected()) |sel| {
        g_status.setLabel(sel);
    }
}

pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;

    try zigsdl.modules.Globals.init(allocator, init.io);
    defer zigsdl.modules.Globals.deinit();

    var button = zigsdl.drawables.Button.new(.{
        .label = "Click me",
        .dim = .{ .w = 140, .h = 36, .d = 1 },
        .font_path = font_path,
        .font_size = font_size,
        .on_click = onButtonClick,
    });
    var button_drawable = button.toDrawable();

    var checkbox = zigsdl.drawables.CheckBox.new(.{
        .dim = .{ .w = 28, .h = 28, .d = 1 },
        .on_toggle = onToggle,
    });
    g_checkbox = &checkbox;
    var checkbox_drawable = checkbox.toDrawable();

    var text_input = try zigsdl.drawables.TextInput.new(allocator, .{
        .placeholder = "Type something...",
        .dim = .{ .w = 200, .h = 32, .d = 1 },
        .font_path = font_path,
        .font_size = font_size,
        .max_len = 64,
        .on_change = onTextChange,
    });
    g_text_input = &text_input;
    var text_input_drawable = text_input.toDrawable();

    var select = try zigsdl.drawables.Select.new(allocator, .{
        .options = &color_options,
        .dim = .{ .w = 140, .h = 32, .d = 1 },
        .font_path = font_path,
        .font_size = font_size,
        .on_change = onSelectChange,
    });
    g_select = &select;
    var select_drawable = select.toDrawable();

    var status = zigsdl.drawables.Text.new(.{
        .text = "Welcome!",
        .font_path = font_path,
        .font_size = font_size,
    });
    g_status = &status;
    var status_drawable = status.toDrawable();

    var button_obj = zigsdl.modules.Object.init(allocator, .{
        .name = "button",
        .position = .{ .x = 30, .y = 30, .z = 1 },
        .drawable = &button_drawable,
    });
    defer button_obj.deinit();

    var checkbox_obj = zigsdl.modules.Object.init(allocator, .{
        .name = "checkbox",
        .position = .{ .x = 30, .y = 90, .z = 1 },
        .drawable = &checkbox_drawable,
    });
    defer checkbox_obj.deinit();

    var checkbox_label = zigsdl.drawables.Text.new(.{
        .text = "Enable",
        .font_path = font_path,
        .font_size = font_size,
    });
    var checkbox_label_drawable = checkbox_label.toDrawable();
    var checkbox_label_obj = zigsdl.modules.Object.init(allocator, .{
        .name = "checkbox_label",
        .position = .{ .x = 70, .y = 95, .z = 1 },
        .drawable = &checkbox_label_drawable,
    });
    defer checkbox_label_obj.deinit();
    try checkbox_obj.addChild(&checkbox_label_obj);

    var text_input_obj = zigsdl.modules.Object.init(allocator, .{
        .name = "text_input",
        .position = .{ .x = 30, .y = 150, .z = 1 },
        .drawable = &text_input_drawable,
    });
    defer text_input_obj.deinit();

    var select_obj = zigsdl.modules.Object.init(allocator, .{
        .name = "select",
        .position = .{ .x = 30, .y = 210, .z = 1 },
        .drawable = &select_drawable,
    });
    defer select_obj.deinit();

    var status_obj = zigsdl.modules.Object.init(allocator, .{
        .name = "status",
        .position = .{ .x = 30, .y = 280, .z = 1 },
        .drawable = &status_drawable,
    });
    defer status_obj.deinit();

    var scene = zigsdl.modules.Scene.init(allocator);
    defer scene.deinit();
    try scene.addObject(&button_obj);
    try scene.addObject(&checkbox_obj);
    try scene.addObject(&text_input_obj);
    try scene.addObject(&select_obj);
    try scene.addObject(&status_obj);

    var screen = try zigsdl.modules.Screen.init(.{
        .title = "UI Demo",
        .width = 400,
        .height = 360,
        .rate = 1000 / 60,
    });
    defer screen.deinit();
    screen.setScene(&scene);
    try screen.open();
}

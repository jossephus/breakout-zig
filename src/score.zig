const r = @import("raylib.zig").raylib;
const std = @import("std");

pub const SCORE_FONT_SIZE: c_int = 16;
pub const SCORE_INC_Y: f32 = 0.0;
pub const SCORE_PROG_INC_Y: f32 = 0.025;

pub const ScoreIndicator = struct {
    value: u32,
    pos: r.Vector2,
    progress: f32,
    start_y: f32,

    pub fn new(value: u32, x: f32, y: f32) ScoreIndicator {
        return ScoreIndicator{
            .value = value,
            .pos = r.Vector2{ .x = x, .y = y },
            .progress = 0.0,
            .start_y = y,
        };
    }

    pub fn draw(s: ScoreIndicator) void {
        var text_buf: [16]u8 = undefined;
        const text_slice = std.fmt.bufPrint(&text_buf, "+{}", .{s.value}) catch return;

        text_buf[text_slice.len] = 0;

        const text_cstr: [*c]const u8 = &text_buf;

        r.DrawText(
            text_cstr,
            @as(c_int, @intFromFloat(s.pos.x)),
            @as(c_int, @intFromFloat(s.pos.y)),
            SCORE_FONT_SIZE,
            r.Color{
                .r = 255,
                .g = 255,
                .b = 255,
                .a = @as(u8, @intFromFloat(s.progress * 255.0)),
            },
        );
    }
};

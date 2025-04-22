const std = @import("std");
const r = @cImport({
    @cInclude("raylib.h");
});

pub const BRICK_W: f32 = 48.0;
pub const BRICK_H: f32 = 16.0;

const BRICK_GAP: f32 = 22.0;
const BRICK_MARGIN: f32 = 32.0;

const BRICK_TEXTURE_DIMS = r.Rectangle{
    .x = 0.0,
    .y = 0.0,
    .width = 48.0,
    .height = 16.0,
};

pub const Brick = struct {
    rec: r.Rectangle,
};

pub fn new_brick(x: f32, y: f32) Brick {
    return Brick{
        .rec = r.Rectangle{
            .x = x,
            .y = y,
            .width = BRICK_W,
            .height = BRICK_H,
        },
    };
}

pub fn new_bricks(allocator: std.mem.Allocator, rows: i32, cols: i32) !std.ArrayList(Brick) {
    var list = try std.ArrayList(Brick).initCapacity(allocator, @as(usize, @intCast(rows * cols)));

    var i: i32 = 0;
    while (i < rows) : (i += 1) {
        var j: i32 = 0;
        while (j < cols) : (j += 1) {
            const bx = @as(f32, @floatFromInt(j)) * BRICK_W + (@as(f32, @floatFromInt(j)) + 1.0) * BRICK_GAP + BRICK_MARGIN;
            const by = @as(f32, @floatFromInt(i)) * BRICK_H + (@as(f32, @floatFromInt(i)) + 1.0) * BRICK_GAP + BRICK_MARGIN;
            try list.append(new_brick(bx, by));
        }
    }

    return list;
}

pub fn draw_brick(b: Brick, t: r.Texture2D) void {
    r.DrawTexturePro(
        t,
        BRICK_TEXTURE_DIMS,
        b.rec,
        r.Vector2{ .x = 0.0, .y = 0.0 },
        0.0,
        r.Color{ .r = 255, .g = 255, .b = 255, .a = 255 },
    );
}

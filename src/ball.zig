const r = @cImport({
    @cInclude("raylib.h");
});
const engine = @import("engine.zig");
const paddle = @import("paddle.zig");

pub const BALL_W: f32 = 16.0;
pub const BALL_H: f32 = 16.0;
pub const BALL_SPEED: f32 = 300.0;

const BALL_TEXTURE_DIMS = r.Rectangle{
    .x = 0.0,
    .y = 0.0,
    .width = 16.0,
    .height = 16.0,
};

pub const Ball = struct {
    rec: r.Rectangle,
    vel: r.Vector2,
};

pub fn new_ball() Ball {
    return Ball{
        .rec = r.Rectangle{
            .x = @as(f32, engine.W_W) / 2.0 - BALL_W / 2.0,
            .y = @as(f32, engine.W_H) - BALL_H - @as(f32, paddle.PADDLE_H) - 40.0,
            .width = BALL_W,
            .height = BALL_H,
        },
        .vel = r.Vector2{
            .x = BALL_SPEED,
            .y = -BALL_SPEED,
        },
    };
}

pub fn drawBall(b: Ball, t: r.Texture2D) void {
    r.DrawTexturePro(
        t,
        BALL_TEXTURE_DIMS,
        b.rec,
        r.Vector2{ .x = 0.0, .y = 0.0 },
        0.0,
        r.Color{ .r = 255, .g = 255, .b = 255, .a = 255 },
    );
}

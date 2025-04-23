const r = @import("raylib.zig").raylib;
const engine = @import("engine.zig");

pub const PADDLE_W: f32 = 128.0;
pub const PADDLE_H: f32 = 16.0;
pub const PADDLE_SPEED: f32 = 500.0;

const PADDLE_TEXTURE_DIMS = r.Rectangle{
    .x = 0.0,
    .y = 0.0,
    .width = 64.0,
    .height = 16.0,
};

pub const Paddle = struct {
    rec: r.Rectangle,

    pub fn new() Paddle {
        return Paddle{
            .rec = r.Rectangle{
                .x = @as(f32, engine.W_W) / 2.0 - PADDLE_W / 2.0,
                .y = @as(f32, engine.W_H) - PADDLE_H - 20.0,
                .width = PADDLE_W,
                .height = PADDLE_H,
            },
        };
    }

    pub fn draw(p: Paddle, t: r.Texture2D) void {
        r.DrawTexturePro(
            t,
            PADDLE_TEXTURE_DIMS,
            p.rec,
            r.Vector2{ .x = 0.0, .y = 0.0 },
            0.0,
            r.Color{ .r = 255, .g = 255, .b = 255, .a = 255 },
        );
    }
};

const std = @import("std");
const r = @import("raylib.zig").raylib;
const bricks = @import("brick.zig");
const balls = @import("ball.zig");
const paddle = @import("paddle.zig");
const particle = @import("particle.zig");
const score = @import("score.zig");
const engine = @import("engine.zig");

const CAMERA_SHAKE_DEC: f32 = 0.8;
const CAMERA_SHAKE_TTL: f32 = 10.0;

pub const GameStatus = enum {
    Start,
    Playing,
    Won,
    Over,
};

fn apply_ball_collision(ball: *balls.Ball, rec: *const r.Rectangle) void {
    const prev_x = ball.rec.x - ball.vel.x;
    const prev_y = ball.rec.y - ball.vel.y;
    if (prev_y + ball.rec.height <= rec.y) {
        ball.vel.y *= -1.0;
    } else if (prev_y >= rec.y + rec.height) {
        ball.vel.y *= -1.0;
    } else if (prev_x + ball.rec.width <= rec.x) {
        ball.vel.x *= -1.0;
    } else if (prev_x >= rec.x + rec.width) {
        ball.vel.x *= -1.0;
    } else {
        ball.vel.y *= -1.0;
    }
}

pub const Game = struct {
    allocator: std.mem.Allocator,
    brick_texture: r.Texture2D,
    ball_texture: r.Texture2D,
    paddle_texture: r.Texture2D,
    status: GameStatus,
    bricks: std.ArrayList(bricks.Brick),
    ball: balls.Ball,
    particle_instances: std.ArrayList(particle.Particles),
    paddle: paddle.Paddle,
    camera_shake_ttl: f32,
    score: u32,
    camera: r.Camera2D,
    score_indicators: std.ArrayList(score.ScoreIndicator),
    score_multiplier: u8,
    //const self = @This();

    pub fn init(allocator: std.mem.Allocator) !Game {
        return Game{
            .allocator = allocator,
            .brick_texture = r.LoadTexture("res/brick.png"),
            .ball_texture = r.LoadTexture("res/tennis.png"),
            .paddle_texture = r.LoadTexture("res/paddle.png"),
            .status = GameStatus.Start,
            .bricks = try bricks.Brick.new_bricks(allocator, 5, 10),
            .ball = balls.Ball.new(),
            .paddle = paddle.Paddle.new(),
            .camera_shake_ttl = 0.0,
            .particle_instances = std.ArrayList(particle.Particles).init(allocator),
            .score = 0,
            .camera = r.Camera2D{
                .offset = r.Vector2{ .x = 0.0, .y = 0.0 },
                .target = r.Vector2{ .x = 0.0, .y = 0.0 },
                .rotation = 0.0,
                .zoom = 1.0,
            },
            .score_indicators = std.ArrayList(score.ScoreIndicator).init(allocator),
            .score_multiplier = 1,
        };
    }

    pub fn restart(self: *Game) !void {
        const allocator = self.allocator;
        self.* = Game{
            .allocator = self.allocator,
            .brick_texture = r.LoadTexture("res/brick.png"),
            .ball_texture = r.LoadTexture("res/tennis.png"),
            .paddle_texture = r.LoadTexture("res/paddle.png"),
            .status = GameStatus.Start,
            .bricks = try bricks.Brick.new_bricks(allocator, 5, 10),
            .ball = balls.Ball.new(),
            .paddle = paddle.Paddle.new(),
            .camera_shake_ttl = 0.0,
            .particle_instances = std.ArrayList(particle.Particles).init(allocator),
            .score = 0,
            .camera = r.Camera2D{
                .offset = r.Vector2{ .x = 0.0, .y = 0.0 },
                .target = r.Vector2{ .x = 0.0, .y = 0.0 },
                .rotation = 0.0,
                .zoom = 1.0,
            },
            .score_indicators = std.ArrayList(score.ScoreIndicator).init(allocator),
            .score_multiplier = 1,
        };
    }

    pub fn deinit(self: *Game) void {
        self.bricks.deinit();
        self.particle_instances.deinit();
        self.score_indicators.deinit();
    }

    pub fn update_game(self: *Game) void {
        switch (self.status) {
            GameStatus.Start => self.update_start(),
            GameStatus.Playing => self.update_playing(),
            GameStatus.Won => self.update_won(),
            GameStatus.Over => self.update_over(),
        }
    }

    pub fn draw(self: *Game) void {
        switch (self.status) {
            GameStatus.Start => self.draw_start(),
            GameStatus.Playing => self.draw_playing(),
            GameStatus.Won => self.draw_won(),
            GameStatus.Over => self.draw_over(),
        }
    }

    fn update_over(self: *Game) void {
        if (r.IsKeyDown(r.KEY_SPACE)) {
            self.deinit();
            self.restart() catch @panic("Unable to restart");
        }
    }

    fn update_won(self: *Game) void {
        if (r.IsKeyDown(r.KEY_SPACE)) {
            self.deinit();
            self.restart() catch @panic("Unable to restart");
        }
    }

    fn update_playing(self: *Game) void {
        const dt = r.GetFrameTime();

        var i: usize = 0;
        while (i < self.bricks.items.len) {
            const b = self.bricks.items[i];
            const collided = r.CheckCollisionRecs(self.ball.rec, b.rec);
            if (!collided) {
                i += 1;
                continue;
            }

            apply_ball_collision(&self.ball, &b.rec);

            self.camera_shake_ttl = CAMERA_SHAKE_TTL;

            //_ = self.particle_instances.append(particle.new_particles(&self.randomness, b.rec.x, b.rec.y));
            _ = self.score_indicators.append(score.ScoreIndicator.new(
                self.score_multiplier,
                b.rec.x + bricks.BRICK_W / 2.0,
                b.rec.y,
            )) catch @panic("error");

            self.score += 1 * self.score_multiplier;
            self.score_multiplier += 1;

            _ = self.bricks.swapRemove(i);
            if (self.bricks.items.len == 0) {
                self.status = .Won;
                return;
            }
        }

        if (r.CheckCollisionRecs(self.ball.rec, self.paddle.rec)) {
            self.score_multiplier = 1;
            if (self.ball.rec.x + balls.BALL_W / 2.0 < self.paddle.rec.x + paddle.PADDLE_W / 2.0) {
                self.ball.vel.x = -paddle.PADDLE_SPEED;
            } else {
                self.ball.vel.x = paddle.PADDLE_SPEED;
            }
            self.ball.vel.y *= -1.0;
            self.ball.rec.y -= balls.BALL_H;
        }

        self.ball.rec.x += self.ball.vel.x * dt;
        self.ball.rec.y += self.ball.vel.y * dt;

        const c_left = self.ball.rec.x < 0.0;
        const c_up = self.ball.rec.y < 0.0;
        const c_right = self.ball.rec.x + self.ball.rec.width > @as(f32, engine.W_W);
        const c_down = self.ball.rec.y + self.ball.rec.height > @as(f32, engine.W_H);

        if (c_left or c_right) self.ball.vel.x *= -1.0;
        if (c_up) self.ball.vel.y *= -1.0;
        if (c_down) {
            self.status = .Over;
            return;
        }

        if (r.IsKeyDown(r.KEY_LEFT)) {
            self.paddle.rec.x -= paddle.PADDLE_SPEED * dt;
        }
        if (r.IsKeyDown(r.KEY_RIGHT)) {
            self.paddle.rec.x += paddle.PADDLE_SPEED * dt;
        }

        for (self.particle_instances.items) |*pi| {
            for (&pi.particles) |*p| {
                p.vel.x += p.acc.x * dt;
                p.vel.y += p.acc.y * dt;
                p.rec.x += p.vel.x * dt;
                p.rec.y += p.vel.y * dt;
                p.ttl = @max(0.0, p.ttl - 1.0);
            }
        }

        var j: usize = 0;
        while (j < self.score_indicators.items.len) {
            var s = &self.score_indicators.items[j];
            const new_p = @as(f32, @floatCast(1.0 - std.math.pow(f64, (1.0 - s.progress), 5.0)));
            s.progress += score.SCORE_PROG_INC_Y;
            s.pos.y = s.start_y - score.SCORE_INC_Y * new_p;
            if (s.progress > 1.0) {
                _ = self.score_indicators.swapRemove(j);
            } else {
                j += 1;
            }
        }
    }

    fn draw_playing(self: *Game) void {
        self.camera_shake_ttl = @max(0.0, self.camera_shake_ttl - CAMERA_SHAKE_DEC);
        self.camera.offset.y = @sin(self.camera_shake_ttl * 2.0) * 2.0 * self.camera_shake_ttl / CAMERA_SHAKE_TTL;
        self.camera.target.x = @sin(self.camera_shake_ttl * 4.0) * 2.0 * self.camera_shake_ttl / CAMERA_SHAKE_TTL;

        r.BeginMode2D(self.camera);

        r.ClearBackground(r.Color{ .r = 0, .g = 0, .b = 0, .a = 255 });

        for (self.bricks.items) |b| {
            b.draw(self.brick_texture);
        }

        for (self.particle_instances.items) |pi| {
            pi.draw_particles();
        }

        self.paddle.draw(self.paddle_texture);
        self.ball.draw(self.ball_texture);

        r.EndMode2D();

        for (self.score_indicators.items) |s| {
            s.draw();
        }

        var fps_text_buf: [32]u8 = undefined;
        const fps_text_slice = std.fmt.bufPrint(&fps_text_buf, "Score: {}", .{self.score}) catch return;
        fps_text_buf[fps_text_slice.len] = 0;
        const fps_text: [*c]const u8 = &fps_text_buf;

        r.DrawText(fps_text, 12, 12, 24, r.Color{ .r = 255, .g = 255, .b = 255, .a = 255 });
    }

    pub fn update_start(self: *Game) void {
        if (r.IsKeyDown(r.KEY_SPACE)) {
            self.status = GameStatus.Playing;
        }
    }

    pub fn draw_start(self: *Game) void {
        _ = self;
        r.ClearBackground(r.Color{ .a = 255 });

        const tx: u32 = 30;
        const font_size: u32 = 22;
        const text = "use left and right arrow keys to move";
        r.DrawText(text, tx, 800 / 2, font_size, r.Color{ .r = 255, .g = 255, .b = 255, .a = 255 });

        const text_2 = "press <space> to start";
        r.DrawText(text_2, tx, 800 / 2 + font_size * 2, font_size, r.Color{ .r = 255, .g = 255, .b = 255, .a = 255 });
    }

    pub fn draw_won(self: *Game) void {
        _ = self;
        r.ClearBackground(r.Color{ .a = 255 });

        const tx: u32 = 30;
        const font_size: u32 = 22;
        const text = "You won :)";
        r.DrawText(text, tx, engine.W_H / 2, font_size, r.Color{ .r = 255, .g = 255, .b = 255, .a = 255 });

        const text_2 = "press <space> to start";
        r.DrawText(text_2, tx, 800 / 2 + font_size * 2, font_size, r.Color{ .r = 255, .g = 255, .b = 255, .a = 255 });
    }

    pub fn draw_over(self: *Game) void {
        _ = self;
        r.ClearBackground(r.Color{ .a = 255 });

        const tx: u32 = 30;
        const font_size: u32 = 22;
        const text = "You lose";
        r.DrawText(text, tx, engine.W_H / 2, font_size, r.Color{ .r = 255, .g = 255, .b = 255, .a = 255 });

        const text_2 = "press <space> to start";
        r.DrawText(text_2, tx, 800 / 2 + font_size * 2, font_size, r.Color{ .r = 255, .g = 255, .b = 255, .a = 255 });
    }
};

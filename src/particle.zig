const r = @cImport({
    @cInclude("raylib.h");
});
const math = @import("std").math;
const Random = @import("std").rand.Random;
const brick = @import("brick.zig");

const PARTICLE_AY: f32 = 2400.0;
const PARTICLE_AX: f32 = 200.0;
const PARTICLE_VY: f32 = -600.0;
const PARTICLE_VX: f32 = 1200.0;
const PARTICLE_W: f32 = 4.0;
const PARTICLE_H: f32 = 4.0;
const PARTICLE_TTL: f32 = 60.0;

pub const Particle = struct {
    vel: r.Vector2,
    acc: r.Vector2,
    rec: r.Rectangle,
    ttl: f32,
};

pub const Particles = struct {
    particles: [10]Particle,
};

pub fn new_particle(x: f32, y: f32, vx: f32, vy: f32, ax: f32) Particle {
    return Particle{
        .vel = r.Vector2{ .x = vx, .y = vy },
        .acc = r.Vector2{ .x = ax, .y = PARTICLE_AY },
        .rec = r.Rectangle{ .x = x, .y = y, .width = PARTICLE_W, .height = PARTICLE_H },
        .ttl = PARTICLE_TTL,
    };
}

pub fn new_particles(rng: *Random, x: f32, y: f32) Particles {
    var pts: [10]Particle = undefined;
    for (pts[0..]) |*p| {
        const rx = (rng.float(f64) - 0.5) * PARTICLE_VX;
        const ry = rng.float(f64) * PARTICLE_VY;
        const ax = (rng.float(f64) - 0.5) * PARTICLE_AX;

        const px = x + brick.BRICK_W * 0.5;
        const py = y + brick.BRICK_H * 0.5;

        p.* = new_particle(@as(f32, @floatCast(px)), @as(f32, @floatCast(py)), @as(f32, @floatCast(rx)), @as(f32, @floatCast(ry)), @as(f32, @floatCast(ax)));
    }

    return Particles{
        .particles = pts,
    };
}

pub fn draw_particles(pi: Particles) void {
    for (pi.particles) |p| {
        r.DrawRectangleRec(
            p.rec,
            r.Color{
                .r = 255,
                .g = 255,
                .b = 255,
                .a = @as(u8, @intFromFloat((p.ttl / PARTICLE_TTL) * 255.0)),
            },
        );
    }
}

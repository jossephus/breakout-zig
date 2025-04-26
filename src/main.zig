const Game = @import("game.zig").Game;
const std = @import("std");
const r = @import("raylib.zig").raylib;
const engine = @import("engine.zig");
const builtin = @import("builtin");

var debug_allocator: std.heap.DebugAllocator(.{}) = .init;

pub fn main() !void {
    const wasm = builtin.target.cpu.arch.isWasm();
    const allocator, const is_debug = gpa: {
        if (wasm) break :gpa .{ std.heap.wasm_allocator, false };
        break :gpa switch (builtin.mode) {
            .Debug, .ReleaseSafe => .{ debug_allocator.allocator(), true },
            .ReleaseFast, .ReleaseSmall => .{ std.heap.smp_allocator, false },
        };
    };
    defer if (is_debug) {
        _ = debug_allocator.deinit();
    };

    r.InitWindow(engine.W_W, engine.W_H, "breakout");
    defer r.CloseWindow();

    var game = try Game.init(allocator);
    defer game.deinit();

    r.SetTargetFPS(60);

    const r_target = r.LoadRenderTexture(engine.W_W, engine.W_H);
    defer r.UnloadRenderTexture(r_target);

    while (!r.WindowShouldClose()) {
        game.update_game();

        const width_scale = @as(f32, @floatFromInt(r.GetScreenWidth())) / @as(f32, engine.W_W);
        const height_scale = @as(f32, @floatFromInt(r.GetScreenHeight())) / @as(f32, engine.W_H);
        const scale = @min(width_scale, height_scale);

        r.BeginTextureMode(r_target);
        game.draw();
        r.EndTextureMode();

        r.BeginDrawing();
        r.ClearBackground(r.Color{ .r = 20, .g = 20, .b = 20, .a = 255 });

        r.DrawTexturePro(
            r_target.texture,
            r.Rectangle{
                .x = 0.0,
                .y = 0.0,
                .width = @as(f32, @floatFromInt(r_target.texture.width)),
                .height = -@as(f32, @floatFromInt(r_target.texture.height)),
            },
            r.Rectangle{
                .x = (@as(f32, @floatFromInt(r.GetScreenWidth())) - @as(f32, engine.W_W) * scale) * 0.5,
                .y = (@as(f32, @floatFromInt(r.GetScreenHeight())) - @as(f32, engine.W_H) * scale) * 0.5,
                .width = @as(f32, engine.W_W) * scale,
                .height = @as(f32, engine.W_H) * scale,
            },
            r.Vector2{ .x = 0.0, .y = 0.0 },
            0.0,
            r.Color{ .r = 255, .g = 255, .b = 255, .a = 255 },
        );

        defer r.EndDrawing();

        //r.ClearBackground(r.Color{ .r = 20, .g = 20, .b = 20, .a = 255 });
    }
}

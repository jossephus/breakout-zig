pub const raylib = @cImport({
    @cInclude("raylib.h");
    @cInclude("raymath.h");
    @cInclude("rlgl.h");
});

pub fn loadTextureFromPath(comptime name: []const u8) raylib.Texture2D {
    const paddle_png = @embedFile(name);

    const image = raylib.LoadImageFromMemory(".png", paddle_png.ptr, paddle_png.len);
    const texture = raylib.LoadTextureFromImage(image);
    defer raylib.UnloadImage(image);
    return texture;
}

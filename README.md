## Breakout Game with Raylib + Zig

Porting https://github.com/nthnd/hare-breakout to Zig to see the difference between hare and Zig in C interop.

You can test it easily using the wasm version on https://jossephus.github.io/breakout-zig/

#### Build

In case if you want to build it, there is flake.nix that will bring all the necessary deps.

```sh
nix develop
zig build run
```

### Demo

![Sample Game](https://github.com/jossephus/breakout-zig/blob/main/assets/breakout.gif)

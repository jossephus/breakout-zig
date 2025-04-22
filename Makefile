windows:
	watchexec -r -c -e zig -- zig build run -Dtarget=x86_64-windows

linux:
	watchexec -r -c -e zig -- zig build run

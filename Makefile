linux:
	zig build run

windows:
	watchexec -r -c -e zig -- zig build run -Dtarget=x86_64-windows


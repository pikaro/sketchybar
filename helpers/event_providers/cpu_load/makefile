CPU_LOAD := $(HOME)/.local/share/sketchybar/cpu_load

$(CPU_LOAD): cpu_load.c cpu.h ../sketchybar.h | $(dir $(CPU_LOAD))
	/usr/bin/clang -std=c99 -O3 \
		$< -o $@

$(dir $(CPU_LOAD)):
	mkdir -p $@

NW_LOAD := $(HOME)/.local/share/sketchybar/network_load

$(NW_LOAD): network_load.c network.h ../sketchybar.h | $(dir $(NW_LOAD))
	/usr/bin/clang -std=c99 -O3 \
		$< -o $@

$(dir $(NW_LOAD)):
	mkdir -p $@

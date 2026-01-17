MENUS := $(HOME)/.local/share/sketchybar/menus

$(MENUS): menus.c | $(dir $(MENUS))
	/usr/bin/clang -std=c99 -O3 \
		-F/System/Library/PrivateFrameworks/ \
		-framework Carbon -framework SkyLight \
		$< -o $@

$(dir $(MENUS)):
	mkdir -p $@

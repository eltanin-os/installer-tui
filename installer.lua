-- from durden (bsd-3)
local function convert_mousexy(x, y, rx, ry)
-- note, this should really take viewport into account (if provided), when
-- doing so, move this to be part of fsrv-resize and manual resize as this is
-- rather wasteful.

-- first, remap coordinate range (x, y are absolute)
	local aprop = image_surface_resolve(content);
	local locx = x - aprop.x;
	local locy = y - aprop.y;

-- take server-side scaling into account
	local res = {};
	local sprop = image_storage_properties(content);
	local sfx = sprop.width / aprop.width;
	local sfy = sprop.height / aprop.height;
	local lx = sfx * locx;
	local ly = sfy * locy;

-- and append our translation
	res[1] = lx;
	res[2] = rx and rx or 0;
	res[3] = ly;
	res[4] = ry and ry or 0;

-- track mouse sample and try to generate relative motion
	if (last_ms and not rx) then
		res[2] = (last_ms[1] - res[1]);
		res[4] = (last_ms[2] - res[3]);
	else
		last_ms = {};
	end

	last_ms[1] = res[1];
	last_ms[2] = res[3];

	return res;
end


local function add_mouse_listener(vid)
	local ctx = {
		name = "cnt_mh",
		mouse = true,
		own =
		function(ctx, tgt)
			return vid == tgt
		end,
		button =
		function(ctx, vid, ind, pressed, x, y)
			target_input(vid, {
				devid = 0,
				subid = ind,
				mouse = true,
				kind = "digital",
				active = pressed
			})
		end,
		motion =
		function(ctx, vid, x, y, rx, ry)
			pos = convert_mousexy(x, y, rx, ry)
			target_input(vid, {
				devid = 0,
				subid = 0,
				kind = "analog",
				mouse = true,
				samples = {pos[1], pos[2]}
			})
			target_input(vid, {
				devid = 0,
				subid = 1,
				kind = "analog",
				mouse = true,
				samples = {pos[3], pos[4]}
			})
		end,
	}
	mouse_addlistener(ctx, {"motion", "button"})
end

local function content_add(vid)
	-- prepare
	move_image(vid, 0, 64)
	resize_image(vid, VRESW, VRESH - 64)
	show_image(vid)
	-- save and replace
	contentsv = content
	content = vid
end

local function content_del(vid)
	if contentsv == nil then
		shutdown()
	end
	delete_image(vid)
	content = contentsv
	contentsv = nil
end

local function spawn_terminal()
	local term_arg = "env=ARCAN_CONNPATH=console:env=ARCAN_TERMINAL_EXEC=luajit tui.lua"
	return launch_avfeed(term_arg, "terminal",
		function(source, status)
			return client_event_handler(source, status)
	end)
end

local function screen_init()
	topbar = color_surface(1, 1, 34, 34, 34)
	move_image(topbar, 0, 0)
	local logo = load_image("images/logo.svg", 1, 64, 64)
	if (not valid_vid(vid)) then
		logo = load_image("images/logo.png", 1, 64, 64)
	end
	title = render_text([[\ffonts/default.ttf,18\bEltanin OS - Glacies]])
	order_image(title, 1)
	show_image({topbar, logo, title})
end

local function screen_resize()
	resize_image(topbar, VRESW, 64)
	center_image(title, topbar)
	if not valid_vid(content) then
		return
	end
	resize_image(content, VRESW, VRESH - 64)
end

function installer()
	keyboard = system_load("builtin/keyboard.lua")()
	system_load("builtin/mouse.lua")()
	mouse_setup(load_image("cursor.png"), 65535, 1, true, false)
	keyboard:kbd_repeat()
	keyboard:load_keymap()
	spawn_terminal()
	screen_init()
	target_alloc("console", client_event_handler)
end

function installer_clock_pulse()
	mouse_tick(1)
	keyboard:tick()
end

function installer_input(input)
	if not valid_vid(content) then
		return
	end
	if input.translated then
		keyboard:patch(input)
	elseif input.mouse then
		mouse_iotbl_input(input)
		return
	end
	target_input(content, input)
end

function client_event_handler(source, status)
	if status.kind == "registered" then
		content_add(source)
		add_mouse_listener(source)
	elseif status.kind == "terminated" then
		content_del(source)
	elseif status.kind == "preroll" then
		target_displayhint(source, VRESW, VRESH, TD_HINT_IGNORE, {ppcm = VPPCM})
		target_fonthint(source, "mono.ttf", 13 * FONT_PT_SZ, 2)
		screen_resize()
	elseif status.kind == "segment_request" then
		if status.segkind == "handover" then
			local vid = accept_target(client_event_handler)
		end
	end
end

function installer_display_state(status)
	resize_video_canvas(VRESW, VRESH)
	mouse_querytarget()
	screen_resize()

	if not valid_vid(content) then
		return
	end
	target_displayhint(content, VRESW, VRESH, TD_HINT_IGNORE)
end

last_vid = nil
cur_vid = nil

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
	logo = load_image("images/logo.svg", 1, 64, 64)
	if (not valid_vid(vid)) then
		logo = load_image("images/logo.png", 1, 64, 64)
	end
	move_image(logo, 0, 0)
	title = render_text([[\ffonts/default.ttf,18\bEltanin OS - Glacies]])
	order_image(title, 2)
	show_image({topbar, logo, title})
end

local function screen_resize()
	resize_image(topbar, VRESW, 64)
	resize_image(logo, 64, 64)
	center_image(title, topbar)
	if not valid_vid(cur_vid) then
		return
	end
	resize_image(cur_vid, VRESW, VRESH - 64)
	target_displayhint(cur_vid, VRESW, VRESH, TD_HINT_IGNORE, {ppcm = VPPCM})
	target_fonthint(cur_vid, "mono.ttf", 12 * FONT_PT_SZ, 2)
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

function installer_input(input)
	if not valid_vid(cur_vid) then
		return
	end
	if input.translated then
		keyboard:patch(input)
	elseif input.mouse then
		mouse_iotbl_input(input)
		return
	end
	target_input(cur_vid, input)
end

function client_event_handler(source, status)
	if status.kind == "registered" then
		last_vid = cur_vid
		cur_vid = source
		move_image(source, 0, 64)
		resize_image(source, VRESW, VRESH - 64)
		show_image(source)
	elseif status.kind == "terminated" then
		delete_image(source)
		if last_vid == nil then
			shutdown()
		end
		cur_vid = last_vid
		last_vid = nil
	elseif status.kind == "resized" then
		resize_video_canvas(VRESW, VRESH)
		screen_resize()
	elseif status.kind == "preroll" then
		screen_resize()
	elseif status.kind == "segment_request" then
		if status.segkind == "handover" then
			local vid = accept_target(client_event_handler)
		end
	end
end

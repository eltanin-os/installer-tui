local dict = require "text"
local tui = require "arcantui"
local texts = dict("en")
local cl = 1 -- lists pos
-- opts
local opts = {
	bootloader = true, -- install bootloader?
	network = false, -- use network to install packages?
}
-- steps
local steps = {
	network = false, -- network set up?
	mount = false, -- mount points set up?
	rootpass = false, -- root pass set up?
}
-- data
local keymap = "us"
local timezone = "UTC"
local filesystem = {}
local rootpass = nil
local users = {}

-- exec routines
local function flush(stdout, fn)
	local ret = false
	local _, alive = stdout:read(
		function(line, eof)
			fn(line)
			ret = eof
		end
	)
	return ret or not alive
end

local function popen(arg, mode)
	local tab = {"/usr/bin/env", "env"}
	if type(arg) == "string" then
		arg = {arg}
	end
	for _, v in ipairs(arg) do
		table.insert(tab, v)
	end
	return wnd:popen(tab, "r", wnd:getenv())
end

local function exec_out(arg)
	local _, stdout, _, _ = popen(arg, "r")
	return stdout
end

local function exec_populate(list, pos, arg)
	local stdout = exec_out(arg)
	stdout:lf_strip(true)
	local cpos = pos
	local fn = function(arg)
		table.insert(list, cpos, {label = arg})
		cpos = cpos + 1
	end
	while not flush(stdout, fn) do
	end
	return cpos
end

-- lists routines
local lists = nil
local function lists_update()
	local list =  {
		-- Main
		{
			{
				label = texts.title,
				itemlabel = true,
			},
			{
				label = "separator",
				separator = true,
			},
			{
				label = texts.language,
			},
			{
				label = texts.keyboard,
			},
			{
				label = texts.timezone,
			},
			{
				label = texts.network,
			},
			{
				label = texts.partitions,
			},
			{
				label = texts.users,
			},
			{
				label = texts.install,
			},
			{
				label = texts.exit,
			},
		},
		-- Language
		{
			{
				label = texts.language_title,
				itemlabel = true,
			},
			{
				label = "separator",
				separator = true,
			},
			{
				label = texts.back,
			},
		},
		-- Keyboard
		{
			{
				label = texts.keyboard_title,
				itemlabel = true,
			},
			{
				label = "separator",
				separator = true,
			},
			{
				label = texts.back,
			},
		},
		-- Timezone
		{
			{
				label = texts.timezone_title,
				itemlabel = true,
			},
			{
				label = "separator",
				separator = true,
			},
			{
				label = texts.back,
			},
		},
		-- Network
		{
			{
				label = texts.network_title,
				itemlabel = true,
			},
			{
				label = "separator",
				separator = true,
			},
			{
				label = texts.network_connect,
			},
			{
				label = texts.network_source,
				checked = opts.network,
				passive = not steps.network,
			},
			{
				label = texts.back,
			},
		},
		-- Partitions
		{
			{
				label = texts.partitions_title,
				itemlabel = true,
			},
			{
				label = "separator",
				separator = true,
			},
			{
				label = texts.partitions_prepare,
			},
			{
				label = texts.partitions_mount,
			},
			{
				label = texts.partitions_bootloader,
				checked = opts.bootloader,
			},
			{
				label = texts.back,
			},
		},
		-- Users
		{
			{
				label = texts.users_title,
				itemlabel = true,
			},
			{
				label = "separator",
				separator = true,
			},
			{
				label = texts.users_add,
			},
			{
				label = texts.users_del,
			},
			{
				label = texts.users_set_rootpass,
			},
			{
				label = texts.back,
			},
		},
		-- Install
		{
			{
				label = texts.install_title,
				itemlabel = true,
			},
			{
				label = "separator",
				separator = true,
			},
			{
				label = "> " .. texts.steps,
				itemlabel = true,
			},
			{
				label = "separator",
				separator = true,
			},
			-- steps content
			{
				label = "separator",
				separator = true,
			},
			{
				label = "> " .. texts.options,
				itemlabel = true,
			},
			{
				label = "separator",
				separator = true,
			},
			-- options content
			{
				label = "separator",
				separator = true,
			},
			{
				label = texts.install,
				passive = not (steps.mount and steps.rootpass)
			},
			{
				label = texts.back,
			},
		},
	}
	-- add languages
	for i, v in ipairs(dict(":list")) do
		local lang = tostring(v)
		local entry = {
			label = dict(lang)[".id"],
			checked = (lang == texts[".dict"]) and true or false,
			dict = lang,
		}
		table.insert(list[2], i + 2, entry)
	end
	-- keyboard populate
	exec_populate(list[3], 3, "setup-list-keymaps")
	-- timezone populate
	exec_populate(list[4], 3, "setup-list-timezones")
	-- create summary
	local size = 0
	for k, _ in pairs(steps) do
		local entry = {
			label = "[" .. (steps[k] and "X" or "-") .. "] " .. texts["steps_" .. k],
			itemlabel = true,
		}
		table.insert(list[8], 5, entry)
		size = size + 1
	end
	for k, _ in pairs(opts) do
		local entry = {
			label = "[" .. (opts[k] and "X" or "-") .. "] " .. texts["opts_" .. k],
			itemlabel = true,
		}
		table.insert(list[8], 8 + size, entry)
	end
	-- return
	lists = list
end

local function lists_current()
	wnd:revert()
	wnd:listview(lists[cl], select_func)
end

local function lists_reset()
	cl = 1
	lists_current()
end

-- screen routines
local function screen_wexec(arg)
	wnd:new_window("handover",
		function(w, new)
			if not new then
				print("handover not permitted")
				return
			end
			lists_current()
			wnd:phandover(
				"/usr/bin/afsrv_terminal",
				"",
				"",
				{ARCAN_TERMINAL_EXEC=arg, ARCAN_ARG="palette=solarized-white"}
			)
		end
	)
end

local function screen_exec(arg, efn)
	local ret = nil
	local _, stdout, _, pid = popen(arg, "r")
	local head = texts.buffer_out .. "\n" .. texts.buffer_esc .. "\n"
	local body = ""
	local buf =  head
	local data = {event = nil, code = nil}
	local showbuffer = function()
		wnd:revert()
		wnd:bufferview(
			buf,
			function(ev)
				data.event = ev
				efn(data)
				data.event = nil
			end,
			{}
		)
	end
	showbuffer()
	local fn = function(arg)
		body = arg .. body
		buf = head .. body
		showbuffer()
	end
	flush(stdout, fn)
	while true do
		local status, code = wnd:pwait(pid)
		flush(stdout, fn)
		if wnd:process() then
			wnd:refresh()
		end
		if not status then
			while not flush(stdout, fn) do
			end
			ret = code
			break
		end
	end
	data.code = ret
	efn(data)
end

local function screen_choose(prompt, arg, fn)
	-- populate
	local entries = {
		{
			label = prompt,
			itemlabel = true,
		},
		{
			label = "separator",
			separator = true,
		}
	}
	local pos = exec_populate(entries, 3, arg)
	table.insert(entries, pos, {label = texts.back})
	-- screen
	selectfn = function(idx)
		if idx == #entries or not idx then
			selectfn = nil
			lists_current()
			return
		end
		fn(entries[idx].label)
	end
	wnd:listview(entries, selectfn)
end


-- input routines
local function getpass(fn, err)
	local opts = {
		cancellable = true,
		mask_character = "*",
	}
	local password = nil
	local handler =
	function(self, msg)
		if msg == "" then
			lists_current()
			return
		end
		password = msg
		local rl = wnd:readline(
			function(self, msg)
				if password ~= msg then
					getpass(fn, true)
				end
				lists_current()
				fn(msg)
			end,
			opts
		)
		rl:set_prompt(texts.getpass_repeat)
	end
	local rl = wnd:readline(handler, opts)
	rl:set_prompt(texts.getpass_passwd)
	if err ~= nil then
		wnd:write_to(0, 1, texts.getpass_err)
	end
end

local function singleln(prompt, fn, opts)
	local line = nil
	local rl = wnd:readline(
		function(self, msg)
			if msg == "" then
				lists_current()
				return
			end
			fn(msg)
		end,
		{cancellable = true, unpack(opts)}
	)
	rl:set_prompt(prompt)
end

local function adduser()
	local name = nil
	local password = nil
	local groups = nil
	-- functions
	local grpsfn =
	function(msg)
		lists_current()
		groups = (msg == nil) and "" or msg
		entry = {
			name = name,
			password = password,
			groups = groups,
		}
		table.insert(users, entry)
	end
	local passfn =
	function(msg)
		password = msg
		singleln(texts.adduser_grps, grpsfn,
			{
				filter =
				function(self, ch, len)
					return string.match(ch, "[%w_,]") ~= nil
				end
			}
		)
	end
	local namefn =
	function(msg)
		name = msg
		getpass(passfn)
	end
	singleln(texts.adduser_name, namefn,
		{
			filter =
			function(self, ch, len)
				if len == 1 then
					return string.match(ch, "%l") ~= nil
				elseif len == 32 then
					return false
				else
					return string.match(ch, "[%l%d%-_]") ~= nil
				end
			end
		}
	)
end

local function deluser()
	entries = {
		{
			label = texts.users,
			itemlabel = true,
		},
		{
			label = "separator",
			separator = true,
		},
		{
			label = texts.back,
		},
	}
	for i, v in ipairs(users) do
		table.insert(entries, 3, {label = v.name})
	end
	selectfn =
	function(idx)
		if idx == #entries or not idx then
			selectfn = nil
			lists_current()
			return
		end
		for i, v in ipairs(users) do
			if entries[idx].label == v.name then
				table.remove(users, i)
				break
			end
		end
		table.remove(entries, idx)
		wnd:listview(entries, selectfn)
	end
	wnd:listview(entries, selectfn)
end

local function addmount()
	local disk = nil
	local fspath = nil
	-- functions
	local mkfsfn =
	function(idx)
		local bool = (idx == 3) and true or false -- yes?
		filesystem[fspath].mkfs = tostring(bool)
		addmount()
	end
	local typefn =
	function(arg)
		filesystem[fspath] = {disk = disk, fstype = arg}
		if filesystem["/"] ~= nil and filesystem["swap"] ~= nil then
			steps.mount = true
			lists_update()
		end
		local entries = {
			{
				label = texts.addmount_askmkfs,
				itemlabel = true,
			},
			{
				label = "separator",
				separator = true,
			},
			{
				label = texts.yes,
			},
			{
				label = texts.no,
			},
		}
		wnd:listview(entries, mkfsfn)
	end
	local pathfn =
	function(arg)
		fspath = arg
		if fspath == "swap" then
			typefn("swap")
			return
		end
		screen_choose(
			texts.partitions_choosetype,
			"setup-list-fstypes",
			typefn
		)
	end
	screen_choose(
		texts.partitions_choose,
		"setup-list-disks",
		function(arg)
			disk = arg
			singleln(texts.addmount, pathfn,
				{
					filter =
					function(self, ch, len)
						return string.match(ch, "[%w/%.%-%_]") ~= nil
					end
				}
			)
		end
	)
end

local function install()
	local setup_mount = function(k, v)
		screen_exec({"setup-mount", v.disk, k, v.fstype, v.mkfs}, selectfn)
	end
	local setup_glacies = function()
		screen_exec({"setup-system", tostring(opts.network)}, selectfn)
	end
	local uid = 1000
	local setup_user = function(i, v)
		screen_exec({"setup-user", v.name, uid, v.password, v.groups}, selectfn)
		uid = uid + 1
	end
	local status = 0
	local setup_laststeps = function(i, v)
		if i == 0 then
			screen_exec({"setup-password", "root", rootpass}, selectfn)
			return
		elseif i == 1 then
			screen_exec("setup-bootloader", selectfn)
			return
		elseif i == 2 then
			screen_exec({"setup-keymap", keymap}, selectfn)
			return
		elseif i == 3 then
			screen_exec({"setup-timezone", timezone}, selectfn)
			return
		end
		local entries = {
			{
				label = (status == 0) and texts.end_success or texts.end_fail,
				itemlabel = true,
			},
			{
				label = "separator",
				separator = true,
			},
			{
				label = texts.end_reboot
			},
			{
				label = texts.back
			},
		}
		local fn =
		function(idx)
			if idx == #entries - 1 then
				popen("setup-reboot")
				return
			end
			lists_reset()
		end
		wnd:listview(entries, fn)
	end
	local tab = {
		{
			fn = setup_mount,
			tab = filesystem,
		},
		{
			fn = setup_glacies,
			tab = {0},
		},
		{
			fn = setup_user,
			tab = users,
		},
		{
			fn = setup_laststeps,
			tab = {0, 1, 2, 3, 4},
		},
	}
	local tabpos = 0
	local state = nil
	local tabinc = function()
		_, state = next(tab, tabpos)
		tabpos = tabpos + 1
	end
	local idx = nil
	selectfn = function(arg)
		if arg.code == nil then
			return
		end
		if arg.code ~= 0 and arg.event == nil then
			status = arg.code
			return
		end
		if status ~= 0 then
			wnd:revert()
			tab[#tab].fn(#tab[#tab].tab, nil)
			return
		end
		local v = nil
		idx, v = next(state.tab, idx)
		if idx == nil then
			tabinc()
			if state ~= nil then
				selectfn({code = 0})
				return
			end
			lists_current()
		end
		wnd:revert()
		state.fn(idx, v)
	end
	tabinc()
	selectfn({code = 0})
end

local listview_func_table = {
	-- Main
	function(idx)
		idx = idx - 1
		-- would be (idx + 1) but with title and sep becomes (idx - 1)
		cl = idx
		wnd:listview(lists[cl], select_func)
	end,
	-- Language
	function(idx)
		for i, v in ipairs(lists[cl], 3, #lists[cl] - 1) do
			v.checked = false
		end
		lists[cl][idx].checked = true
		texts = dict(lists[cl][idx].dict)
		lists_update()
		lists_current()
	end,
	-- Keyboard
	function(idx)
		for i, v in ipairs(lists[cl], 3, #lists[cl] - 1) do
			v.checked = false
		end
		lists[cl][idx].checked = true
		keymap = lists[cl][idx].label
		lists_update()
		lists_reset()
	end,
	-- Timezone
	function(idx)
		screen_choose(
			texts.timezone_choose,
			{ "setup-list-timezones", lists[cl][idx].label },
			function(arg)
				timezone = lists[cl][idx].label .. arg
				lists_reset()
			end
		)
	end,
	-- Network
	function(idx)
		if idx == 3 then
			screen_choose(
				texts.network_choose,
				"setup-list-interfaces",
				function(arg)
					local fn = function(ev)
						if ev.event ~= nil then
							lists_current()
						end
						if ev.code == 0 then
							steps.network = true
							lists_update()
							lists_current()
						end
					end
					screen_exec({"setup-network", arg}, fn)
				end
			)
		elseif idx == 4 then
			opts.network = not opts.network
			lists_update()
			lists_current()
		end
	end,
	-- Partitions
	function(idx)
		if idx == 3 then
			screen_choose(
				texts.partitions_choose,
				"setup-list-devices",
				function(arg)
					screen_wexec("cfdisk " .. arg)
				end
			)
		elseif idx == 4 then
			addmount()
		elseif idx == 5 then
			opts.bootloader = not opts.bootloader
			lists_update()
			lists_current()
		end
	end,
	-- Users
	function(idx)
		if idx == 3 then
			adduser()
		elseif idx == 4 then
			deluser()
		elseif idx == 5 then
			getpass(
				function(pass)
					rootpass = pass
					steps.rootpass = true
					lists_update()
				end
			)
		end
	end,
	-- Install
	function(idx)
		install()
	end,
}

function select_func(idx)
	if idx == #lists[cl] or not idx then
		if cl == 1 then
			wnd:close()
		else
			lists_reset()
		end
		return
	end
	listview_func_table[cl](idx)
end

local function redraw(wnd)
end

wnd = tui.open("Eltanin Installer", "", {handlers = {resized = redraw}})
lists_update()
lists_reset()

while (wnd:process() and wnd:alive()) do
	wnd:refresh()
end

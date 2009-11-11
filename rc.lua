---------------------------------------------------------------------------
-- @author Andrew N Golovkov &lt;andrew.golovkov@gmail.com&gt;
-- @copyright 2009 Andrew N Golovkov
-- @release v9999
---------------------------------------------------------------------------

-- загрузка дефолтного конфига
--dofile("/etc/xdg/awesome/rc.lua")

-- Standard awesome library
require("awful")
require("awful.autofocus")
require("awful.rules")
-- Theme handling library
require("beautiful")
-- Notification library
require("naughty")

local util = require("lib.util")
local os = os

-- Загрузка модулей
local io = io
local math = math
local awful = require("awful")
local beautiful = beautiful
local tostring, tonumber = tostring, tonumber
local configdir = os.getenv("HOME") .. "/.config/awesome"
package.cpath = configdir .. "/contrib/LuaXml/?.so;" .. package.cpath
local log = util.log
local text = require("lib.widget.text")
local weather = require("lib.widget.yandex_weather")

-- Установка темы
beautiful.init(configdir .. "/theme.lua")

-- настройки терминала и редактора
terminal = "urxvt"
editor = "vim"
editor_cmd = terminal .. " -e " .. editor

modkey = "Mod4"

tags = {}
tags[1] = awful.tag({ "term", "browser", "mail", "others" }, 1)
for i = 2, screen.count() do
   tags[i] = {}
end

-- Менюшка
mymainmenu = awful.menu({ items =
			  { { "restart", awesome.restart },
			    { "open terminal", terminal },
			    { "edit config", editor_cmd .. " " .. awful.util.getdir("config") .. "/rc.lua"  } } })

-- Список раскладок окон.
layouts = {
   awful.layout.suit.tile,
   -- awful.layout.suit.tile.left,
   -- awful.layout.suit.tile.bottom,
   -- awful.layout.suit.tile.top,
   awful.layout.suit.fair,
   -- awful.layout.suit.fair.horizontal,
   -- awful.layout.suit.spiral,
   -- awful.layout.suit.spiral.dwindle,
   awful.layout.suit.max,
   awful.layout.suit.max.fullscreen,
   awful.layout.suit.magnifier,
   awful.layout.suit.floating
}

-- функция получения текста трафика на интерфейсе
function get_traffic(interface)
   local int = tostring(interface) or "eth0"

   local rx = util.file_read("/sys/class/net/" .. int .. "/statistics/rx_bytes")
   local tx = util.file_read("/sys/class/net/" .. int .. "/statistics/tx_bytes")

   local text = "[" .. int .. ":"
   local number, mod = "None", ""
   if tx and rx then
      number = (tonumber(rx)+tonumber(tx))
      if number > 10*1024 then
	 number = number/1024
	 if number > 10*1024 then
	    number = number/1024
	    if number > 10*1024 then
	       number = number/1024
	       mod = "g"
	    else
	       mod = "m"
	    end
	 else
	    mod = "k"
	 end
      else
	 mod = "b"
      end
      number = math.floor(number)
   end
   text = text .. number .. mod .. "]"
   data = {
      int = int,
      tx = tx,
      rx = rx,
      sum = number,
      mod = mod }
   return text
end

-- функция получения заряда батареи
function battery_status(battery)
   local current, total, rate, state, warning = 0, 0, 0, 0, false
   local battery = battery or 0
   battery = tostring(battery)

   local fbatstate = io.open("/proc/acpi/battery/BAT".. battery .."/state", "r")
   local fbatinfo = io.open("/proc/acpi/battery/BAT".. battery .. "/info", "r")
   if fbatstate then
      -- Получение текущего заряда, скорости разрядки и состояния.
      for l in fbatstate:lines("/proc/acpi/battery/BAT".. battery .."/state") do
	 if l:match("remaining capacity:") then current = l:gsub("remaining capacity:%s*(%d+) mAh$", "%1") end
	 if l:match("present rate:") then rate = l:gsub("present rate:%s*(%d+) mA$", "%1") end
	 if l:match("charging state:") then state = l:gsub("charging state:%s*(%S+)$", "%1") end
      end
      fbatstate:close() 
   end

   if fbatinfo then
      -- Получение максимального заряда и уровня опасного зазряда.
      for l in fbatinfo:lines("/proc/acpi/battery/BAT".. battery .. "/info") do
	 if l:match("last full capacity:") then total = l:gsub("last full capacity:%s*(%d+) mAh$", "%1") end
	 if l:match("design capacity warning:") then
	    if tonumber(current) <= tonumber(l:gsub("design capacity warning:%s*(%d+) mAh$", "%1"), 10 ) then
	       warning = true else warning = false
	    end
	 end
      end
      fbatinfo:close() 
   end

   total = tonumber(total) or 0
   current = tonumber(current) or 0
   rate = tonumber(rate) or 0

   -- Подсчёт оставшегося времени.
   local elapsed = "00:00"
   if rate ~= 0 then
      elapsed = os.date("!%H:%M", (current/rate)*3600)
   end

   -- Подсчёт процентов разряда.
   local percent = math.floor(current/total*100)
   if percent > 100 then percent = 100 end
   if percent < 0 then percent = 0 end

   -- Обновление данных.
   local data = {
      battery = battery,
      current = current,
      rate = rate,
      total = total,
      state = state,
      warning = warning,
      percent = percent,
      elapsed = elapsed}
   return data
end

-- виджет индикатора ppp0
myppp0 = lib.widget.text({ align = "left", timeout = 10, update_function = function() return get_traffic("ppp0") end })
-- виджет индикатора заряда батареи
mybattery = lib.widget.text({ align = "left", timeout = 10,
			      update_function = function()
						   local data = battery_status(0)
						   local btheme = beautiful.get()
						   theme = btheme.battery or {}
						   theme.warning = btheme.battery.warning or "red"
						   theme.charging = btheme.battery.charging or "green"
						   theme.discharging = btheme.battery.discharging or "yellow"
						   theme.charged = btheme.battery.charged or btheme.fg_normal or "white"
						   
						   -- Получение цвета.
						   local color
						   if warning then
						      color = theme.warning
						   else
						      color = theme[data.state] or theme.charged or "white"
						   end
						   
						   -- Гламурная стрелочка.
						   local arrow
						   if data.state == "charging" then
						      arrow = "↑"
						   else if data.state == "discharging" then
							 arrow = "↓"
						      end
						   end
						   if arrow then arrow = arrow .. " " else arrow = "" end
						   return "[Bat" .. data.battery .. ":" .. arrow .. "<span color='" .. color .. "'>" .. data.percent .. "%</span>] "
						end })
-- batterytip = lib.widget.text({ align = "left" })
-- mybattery:add_signal("mouse::enter", function() end)
-- mybattery:add_signal("mouse::leave", function() end)

-- нормальный вид часов, а не дефолтный
mytextclock = awful.widget.textclock({align = "left"}, " %Y.%m.%d, %A, %T ", 1)

-- панелька
-- Create a wibox for each screen and add it
mywibox = {}
mypromptbox = {}
mylayoutbox = {}
mytaglist = {}
mytaglist.buttons = awful.util.table.join(
                    awful.button({ }, 1, awful.tag.viewonly),
                    awful.button({ modkey }, 1, awful.client.movetotag),
                    awful.button({ }, 3, awful.tag.viewtoggle),
                    awful.button({ modkey }, 3, awful.client.toggletag),
                    awful.button({ }, 4, awful.tag.viewnext),
                    awful.button({ }, 5, awful.tag.viewprev)
                    )

-- изменение панели экрана
mypromptbox = awful.widget.prompt({ layout = awful.widget.layout.horizontal.leftright })
mylayoutbox = awful.widget.layoutbox(1)
mylayoutbox:buttons(awful.util.table.join(
		       awful.button({ }, 1, function () awful.layout.inc(layouts, 1) end),
		       awful.button({ }, 3, function () awful.layout.inc(layouts, -1) end),
		       awful.button({ }, 4, function () awful.layout.inc(layouts, 1) end),
		       awful.button({ }, 5, function () awful.layout.inc(layouts, -1) end)))
mytaglist = awful.widget.taglist(1, awful.widget.taglist.label.all, mytaglist.buttons)

mytaglist.buttons = awful.util.table.join(
                    awful.button({ }, 1, awful.tag.viewonly),
                    awful.button({ modkey }, 1, awful.client.movetotag),
                    awful.button({ }, 3, awful.tag.viewtoggle),
                    awful.button({ modkey }, 3, awful.client.toggletag),
                    awful.button({ }, 4, awful.tag.viewnext),
                    awful.button({ }, 5, awful.tag.viewprev)                     )

-- панель задач
mytasklist = {}
mytasklist.buttons = awful.util.table.join(
                     awful.button({ }, 1, function (c)
                                              if not c:isvisible() then
                                                  awful.tag.viewonly(c:tags()[1])
                                              end
                                              client.focus = c
                                              c:raise()
                                          end),
                     awful.button({ }, 3, function ()
                                              if instance then
                                                  instance:hide()
                                                  instance = nil
                                              else
                                                  instance = awful.menu.clients({ width=250 })
                                              end
                                          end),
                     awful.button({ }, 4, function ()
                                              awful.client.focus.byidx(1)
                                              if client.focus then client.focus:raise() end
                                          end),
                     awful.button({ }, 5, function ()
                                              awful.client.focus.byidx(-1)
                                              if client.focus then client.focus:raise() end
                                          end))
mytasklist = awful.widget.tasklist(function(c)
				      local text, bg, _, icon = awful.widget.tasklist.label.currenttags(c, 1)
				      return text, bg, nil, icon
				   end,
				   mytasklist.buttons)
-- Трей
mysystray = widget({ type = "systray" })


-- Погода же.
myweather = weather({ city = 27612 }) -- Moscow

--awful.widget.wibox.stretch(myweather)
mywibox = awful.wibox({ position = "top", screen = 1 })
-- виджеты панельки
mywibox.widgets = {
   { mytaglist,
     mybattery,
     mypromptbox,
     layout = awful.widget.layout.horizontal.leftright },
   mylayoutbox,
   mytextclock,
   myweather,
   myppp0,
   mysystray,
   mytasklist,
   layout = awful.widget.layout.horizontal.rightleft }
-- log("weather", myweather.widgets)

-- {{{ Mouse bindings
root.buttons(awful.util.table.join(
    awful.button({ }, 3, function () mymainmenu:toggle() end),
    awful.button({ }, 4, awful.tag.viewnext),
    awful.button({ }, 5, awful.tag.viewprev)
))
-- }}}


-- {{{ Key bindings
globalkeys = awful.util.table.join(
    awful.key({ modkey,           }, "Left",   awful.tag.viewprev       ),
    awful.key({ modkey,           }, "Right",  awful.tag.viewnext       ),
    awful.key({ modkey,           }, "Escape", awful.tag.history.restore),

    awful.key({ modkey,           }, "j",
        function ()
            awful.client.focus.byidx( 1)
            if client.focus then client.focus:raise() end
        end),
    awful.key({ modkey,           }, "k",
        function ()
            awful.client.focus.byidx(-1)
            if client.focus then client.focus:raise() end
        end),
    awful.key({ modkey,           }, "w", function () mymainmenu:show(true)        end),

    -- Layout manipulation
    awful.key({ modkey, "Shift"   }, "j", function () awful.client.swap.byidx(  1)    end),
    awful.key({ modkey, "Shift"   }, "k", function () awful.client.swap.byidx( -1)    end),
    awful.key({ modkey, "Control" }, "j", function () awful.screen.focus_relative( 1) end),
    awful.key({ modkey, "Control" }, "k", function () awful.screen.focus_relative(-1) end),
    awful.key({ modkey,           }, "u", awful.client.urgent.jumpto),
    awful.key({ modkey,           }, "Tab",
        function ()
            awful.client.focus.history.previous()
            if client.focus then
                client.focus:raise()
            end
        end),

    -- Standard program
    awful.key({ modkey,           }, "Return", function () awful.util.spawn(terminal) end),
    awful.key({ modkey, "Control" }, "r",     awesome.restart),
    awful.key({ modkey, "Shift"   }, "q",     awesome.quit),
    awful.key({ modkey,           }, "l",     function () awful.tag.incmwfact( 0.05)    end),
    awful.key({ modkey,           }, "h",     function () awful.tag.incmwfact(-0.05)    end),
    awful.key({ modkey, "Shift"   }, "h",     function () awful.tag.incnmaster( 1)      end),
    awful.key({ modkey, "Shift"   }, "l",     function () awful.tag.incnmaster(-1)      end),
    awful.key({ modkey, "Control" }, "h",     function () awful.tag.incncol( 1)         end),
    awful.key({ modkey, "Control" }, "l",     function () awful.tag.incncol(-1)         end),
    awful.key({ modkey,           }, "space", function () awful.layout.inc(layouts,  1) end),
    awful.key({ modkey, "Shift"   }, "space", function () awful.layout.inc(layouts, -1) end),

    -- Prompt
--    awful.key({ "Alt"  },            "F2",    function () mypromptbox:run() end),
    awful.key({ modkey },            "F2",    function () mypromptbox:run() end),

    awful.key({ modkey }, "x",
              function ()
                  awful.prompt.run({ prompt = "Run Lua code: " },
                  mypromptbox.widget,
                  awful.util.eval, nil,
                  awful.util.getdir("cache") .. "/history_eval")
              end)
)

clientkeys = awful.util.table.join(
    awful.key({ modkey,           }, "f",      function (c) c.fullscreen = not c.fullscreen  end),
    awful.key({ modkey, "Shift"   }, "c",      function (c) c:kill()                         end),
    awful.key({ modkey, "Control" }, "space",  awful.client.floating.toggle                     ),
    awful.key({ modkey, "Control" }, "Return", function (c) c:swap(awful.client.getmaster()) end),
    awful.key({ modkey,           }, "o",      awful.client.movetoscreen                        ),
    awful.key({ modkey, "Shift"   }, "r",      function (c) c:redraw()                       end),
    awful.key({ modkey,           }, "n",      function (c) c.minimized = not c.minimized    end),
    awful.key({ modkey,           }, "m",
        function (c)
            c.maximized_horizontal = not c.maximized_horizontal
            c.maximized_vertical   = not c.maximized_vertical
        end)
)

-- Compute the maximum number of digit we need, limited to 9
keynumber = 0
for s = 1, screen.count() do
   keynumber = math.min(9, math.max(#tags[s], keynumber));
end

-- Bind all key numbers to tags.
-- Be careful: we use keycodes to make it works on any keyboard layout.
-- This should map on the top row of your keyboard, usually 1 to 9.
for i = 1, keynumber do
    globalkeys = awful.util.table.join(globalkeys,
        awful.key({ modkey }, "#" .. i + 9,
                  function ()
                        local screen = mouse.screen
                        if tags[screen][i] then
                            awful.tag.viewonly(tags[screen][i])
                        end
                  end),
        awful.key({ modkey, "Control" }, "#" .. i + 9,
                  function ()
                      local screen = mouse.screen
                      if tags[screen][i] then
                          awful.tag.viewtoggle(tags[screen][i])
                      end
                  end),
        awful.key({ modkey, "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus and tags[client.focus.screen][i] then
                          awful.client.movetotag(tags[client.focus.screen][i])
                      end
                  end),
        awful.key({ modkey, "Control", "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus and tags[client.focus.screen][i] then
                          awful.client.toggletag(tags[client.focus.screen][i])
                      end
                  end))
end

clientbuttons = awful.util.table.join(
    awful.button({ }, 1, function (c) client.focus = c; c:raise() end),
    awful.button({ modkey }, 1, awful.mouse.client.move),
    awful.button({ modkey }, 3, awful.mouse.client.resize))

-- Set keys
root.keys(globalkeys)
-- }}}

-- {{{ Rules
awful.rules.rules = {
    -- All clients will match this rule.
    { rule = { },
      properties = { border_width = beautiful.border_width,
                     border_color = beautiful.border_normal,
                     focus = true,
                     keys = clientkeys,
                     buttons = clientbuttons } },
    { rule = { class = "MPlayer" },
      properties = { floating = true } },
    { rule = { class = "pinentry" },
      properties = { floating = true } },
    { rule = { class = "gimp" },
      properties = { floating = true } },
    { rule = { class = "URxvt" },
      properties = { maximized_vertical = true, maximized_horizontal = true, tag = tags[1][1] } },
    { rule = { class = "Firefox" },
      properties = { tag = tags[1][2] } },
}
-- }}}

-- {{{ Signals
-- Signal function to execute when a new client appears.
client.add_signal("manage", function (c, startup)
    -- Add a titlebar
    -- awful.titlebar.add(c, { modkey = modkey })

    -- Enable sloppy focus
    c:add_signal("mouse::enter", function(c)
        if awful.layout.get(c.screen) ~= awful.layout.suit.magnifier
            and awful.client.focus.filter(c) then
            client.focus = c
        end
    end)

    if not startup then
        -- Set the windows at the slave,
        -- i.e. put it at the end of others instead of setting it master.
        -- awful.client.setslave(c)

        -- Put windows in a smart way, only if they does not set an initial position.
        if not c.size_hints.user_position and not c.size_hints.program_position then
            awful.placement.no_overlap(c)
            awful.placement.no_offscreen(c)
        end
    end
end)

client.add_signal("focus", function(c) c.border_color = beautiful.border_focus end)
client.add_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)
-- }}}

-- ну и напоследок
awful.util.spawn("xset r rate 200 70")
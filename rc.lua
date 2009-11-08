-- загрузка дефолтного конфига
dofile("/etc/xdg/awesome/rc.lua")

require("awful.util")
-- изменение путей загрузки
--package.path = os.getenv("HOME") .. "/.config/awesome/lib/?.lua;" .. package.path

local util = require("lib.util")
local os = os

-- Загрузка модулей
local io = io
local math = math
local text = require("lib.widget.text")
local awful = require("awful")
local beautiful = beautiful
local tostring, tonumber = tostring, tonumber

-- Установка темы
beautiful.init(os.getenv("HOME") .. "/.config/awesome/theme.lua")

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
myppp0 = awful.widget.text({ align = "left", timeout = 10, update_function = function() return get_traffic("ppp0") end })
-- виджет индикатора заряда батареи
mybattery = awful.widget.text({align = "left", timeout = 10,
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
						 end})
-- нормальный вид часов, а не дефолтный
mytextclock = awful.widget.textclock({align = "left"}, " %Y.%m.%d, %A, %T ", 1)

terminal = "urxvt"

-- список раскладок окон
layouts = {
   awful.layout.suit.tile,
   awful.layout.suit.max,
   awful.layout.suit.max.fullscreen,
   awful.layout.suit.magnifier,
   awful.layout.suit.floating
}

-- изменение панели экрана
function recreate_screen(s)
   mypromptbox[s] = awful.widget.prompt({ layout = awful.widget.layout.horizontal.leftright })
   mylayoutbox[s] = awful.widget.layoutbox(s)
   mylayoutbox[s]:buttons(awful.util.table.join(
			     awful.button({ }, 1, function () awful.layout.inc(layouts, 1) end),
			     awful.button({ }, 3, function () awful.layout.inc(layouts, -1) end),
			     awful.button({ }, 4, function () awful.layout.inc(layouts, 1) end),
			     awful.button({ }, 5, function () awful.layout.inc(layouts, -1) end)))
   mytaglist[s] = awful.widget.taglist(s, awful.widget.taglist.label.all, mytaglist.buttons)
--floating_icon
   mytasklist[s] = awful.widget.tasklist(function(c)
					    local text, bg, _, icon = awful.widget.tasklist.label.currenttags(c, s)
					    return text, bg, nil, icon
					 end,
					 mytasklist.buttons)
   -- панелька
   mywibox[s] = awful.wibox({ position = "top", screen = s })
   -- виджеты панельки
   mywibox[s].widgets = {
      {
	 mytaglist[s],
	 mybattery,
	 mypromptbox[s],
	 layout = awful.widget.layout.horizontal.leftright
      },
      mylayoutbox[s],
      mytextclock,
      myppp0,
      mysystray,
      mytasklist[s],
      layout = awful.widget.layout.horizontal.rightleft
   }
end
recreate_screen(1)

-- правила окон
awful.rules.rules = awful.util.table.join(
   awful.rules.rules,
   { { rule = { class = "URxvt" },
       properties = { maximized_vertical = true, maximized_horizontal = true } },
--     { rule = { class = "MPlayer" },
--       properties = { tag = tags[1][2] } } 
  } ) -- join

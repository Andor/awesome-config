-- загрузка дефолтного конфига
dofile("/etc/xdg/awesome/rc.lua")

require("awful.util")
-- изменение путей загрузки
package.path = os.getenv("HOME") .. "/.config/awesome/lib/?.lua;" .. package.path
local log = require "log"

-- Theme settings
beautiful.init(os.getenv("HOME") .. "/.config/awesome/theme.lua")

-- Загрузка модулей
local io = io
local math = math
local battery = require("battery")
local text = require("text")
local awful = require("awful")
local join = awful.util.table.join

-- нормальный вид часов, а не дефолтный
mytextclock = awful.widget.textclock({align = "left"}, " %Y.%m.%d, %A, %T ", 1)
-- виджет индикатора заряда батареи
mybattery = awful.widget.battery({ align = "left" }, { battery = 0, timeout = 5 })

function get_traffic(interface)
   local int = tostring(interface) or "eth0"
   local frx = io.open("/sys/class/net/" .. int .. "/statistics/rx_bytes", "r")
   local ftx = io.open("/sys/class/net/" .. int .. "/statistics/tx_bytes", "r")
   local rx, tx = 0,0

   if frx then
      rx = frx:read("*l")
      rx = tonumber(rx)
      frx:close()
   end
   if ftx then
      tx = ftx:read("*l")
      tx = tonumber(tx)
      ftx:close()
   end

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
   return text
end
-- виджет индикатора ppp0
myppp0 = awful.widget.text({ align = "left", timeout = 10, update_function = function() return get_traffic("ppp0") end })

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


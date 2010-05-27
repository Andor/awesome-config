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
configdir = os.getenv("HOME") .. "/.config/awesome"
package.cpath = configdir .. "/contrib/LuaXml/?.so;" .. package.cpath
local log = util.log
local text = require("lib.widget.text")
-- local weather = require("lib.widget.yandex_weather")

-- Установка темы
beautiful.init(configdir .. "/theme.lua")

-- настройки терминала и редактора
terminal = "konsole"
editor = "emacs"
editor_cmd = terminal .. " -e " .. editor

modkey = "Mod4"

tags = {}
tags[1] = awful.tag({ "term", "browser", "mail", "others" }, 1)
for i = 2, screen.count() do
   tags[i] = awful.tag({ "all" }, i)
end

-- Менюшка
mymainmenu = awful.menu( {
      items = {
	 { "open terminal", terminal },
	 { "edit config", editor_cmd .. " " .. awful.util.getdir("config") .. "/rc.lua"  },
	 { "restart", awesome.restart },
	 { "quit", awesome.quit }
      }
   }
		      )

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

-- загрузка индикатора сети
require("lib.hw.network")
-- виджет индикатора ppp0
myppp0 = lib.widget.text({ align = "left", timeout = 10, update_function = function() return get_interface_data("ppp0").text end })
-- batterytip = lib.widget.text({ align = "left" })
-- mybattery:add_signal("mouse::enter", function() end)
-- mybattery:add_signal("mouse::leave", function() end)

-- загрузка индикатора батареи
require("lib.hw.battery")
-- виджет индикатора заряда батареи
mybattery = lib.widget.text({ align = "left", timeout = 10, update_function = get_battery_text })

-- Трей
mysystray = widget({ type = "systray" })

-- Погода же.
-- myweather = weather({ city = 27612 }) -- Moscow aka Москва

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

--awful.widget.wibox.stretch(myweather)
mywibox = awful.wibox({ position = "top", screen = 1 })
-- виджеты панельки
mywibox.widgets = {
   { mytaglist,
     mybattery,
--     myweather,
     mypromptbox,
     layout = awful.widget.layout.horizontal.leftright },
   mylayoutbox,
   mytextclock,
--   myppp0,
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

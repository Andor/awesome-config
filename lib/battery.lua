---------------------------------------------------------------------------
-- @author Andrew N Golovkov &lt;andrew.golovkov@gmail.com&gt;
-- @copyright 2009 Andrew N Golovkov
-- @release v0.2
---------------------------------------------------------------------------

local setmetatable = setmetatable
local os = os
local io = io
local pairs = pairs
local capi = { widget = widget,
               timer = timer }
local math = require("math")
local beautiful = require("beautiful")
local tostring, tonumber = tostring, tonumber

-- Виджет индикатора разряда батареи.
module("awful.widget.battery")

-- @return Обновление данных батареи.
local function update_data(self)
   local current, total, rate, state, warning = 0, 0, 0, 0, false

   local fbatstate = io.open("/proc/acpi/battery/BAT".. self.battery .."/state", "r")
   local fbatinfo = io.open("/proc/acpi/battery/BAT".. self.battery .. "/info", "r")
   if fbatstate then
      -- Получение текущего заряда, скорости разрядки и состояния.
      for l in fbatstate:lines("/proc/acpi/battery/BAT".. self.battery .."/state") do
	 if l:match("remaining capacity:") then current = l:gsub("remaining capacity:%s*(%d+) mAh$", "%1") end
	 if l:match("present rate:") then rate = l:gsub("present rate:%s*(%d+) mA$", "%1") end
	 if l:match("charging state:") then state = l:gsub("charging state:%s*(%S+)$", "%1") end
      end
      fbatstate:close() 
   end

   if fbatinfo then
      -- Получение максимального заряда и уровня опасного зазряда.
      for l in fbatinfo:lines("/proc/acpi/battery/BAT".. self.battery .. "/info") do
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

   -- Обновление внутренних данных.
   local new_data = {
      current = current,
      rate = rate,
      total = total,
      state = state,
      warning = warning,
      percent = percent,
      elapsed = elapsed }

   for k, v in pairs(new_data) do
      self[k] = v
   end
end

-- Функция перерисовки, используемая по-умолчанию
local function update_text(self)
   -- Определение цвета 
   local color
   if warning then 
      color = self.theme.warning
   else
      color = self.theme[self.state] or self.theme.charged or "white"
   end

   -- Обновление текста виджета
   return "[Bat" .. self.battery .. ":<span color='" .. color .. "'>".. self.percent .. "%</span>] "
end

-- @param args Стандартные аргументы виджета textbox.
-- @param params Параметры виджета:<br/>
-- <code>battery</code> Номер батареи, заряд которой будет выводиться.
-- <code>timeout</code> Таймаут обновления виджета.
-- <code>update_function</code> Функция для обновления текста виджета, должна возвращать строку, которая
-- будет написана на самом виджете. По-умолчанию используется update_text().
-- @return Полученный виджет.
local function new(args, params)
   local ba = {}
   local params = params or {}
   ba = {
      battery = params.battery or 0,
      timeout = params.timeout or 20,
   }
   update_data(ba)

   -- Экспорт
   ba.update_data = function() update_data(ba) end
   ba.update_text = function() return update_text(ba) end

   -- Использование внешней функции, если она задана
   if params.update_function and type(params.update_function) == "function" then
      ba.update = params.update_function
   else
      ba.update = ba.update_text
   end

   -- Загрузка цветовой темы
   local theme = beautiful.get()
   theme.battery = theme.battery or {}
   ba.theme = {
      warning = theme.battery.warning or "red",
      charging = theme.battery.charging or "green",
      discharging = theme.battery.discharging or "yellow",
      charged = theme.battery.charged or theme.fg_normal or "white",
   }

   -- Создание виджета
   local args = args or {}
   args.type = "textbox"
   ba.widget = capi.widget(args)

   ba.widget.text = ba.update()
   ba.timer = capi.timer({ timeout = 5 })
   ba.timer:add_signal("timeout", function()
				     ba.update_data()
				     ba.widget.text = ba.update()
				  end)
   ba.timer:start()
   return ba
end

setmetatable(_M, { __call = function(_, ...) return new(...) end })

-- vim: filetype=lua:expandtab:shiftwidth=4:tabstop=8:softtabstop=4:encoding=utf-8:textwidth=80

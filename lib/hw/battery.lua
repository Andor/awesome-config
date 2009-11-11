local io = io
local os = os

-- функция получения заряда батареи
function get_battery_data(battery)
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
      elapsed = elapsed }
   return data
end

function get_battery_text()
   local data = get_battery_data(0)
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
end

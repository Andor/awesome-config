---------------------------------------------------------------------------
-- @author Andrew N Golovkov &lt;andrew.golovkov@gmail.com&gt;
-- @copyright 2009 Andrew N Golovkov
-- @release v0.1
---------------------------------------------------------------------------

local http = require("socket.http")
local util = require("lib.util")
require("contrib.LuaXml.LuaXml")
local LuaXml = xml
local os = os
local type = type
local setmetatable = setmetatable
local tonumber, tostring = tonumber, tostring
local ipairs = ipairs
local awful = awful
local string = string
local io = io
local timer = timer
local capi = {
   image = image,
   widget = widget,
   wibox = wibox,
}
require("lib.util")
local log = lib.util.log

module("lib.widget.yandex_weather")

-- Локальные данные.
local data = {}
PROXY = os.getenv("http_proxy") or nil

local function image(data, path)
   local image = data
   local cache = awful.util.getdir("cache") .. "/weather/" .. string.gsub(path, "/", "__")
   if not image or not data.image_path or data.image_path ~= path then
      -- проверить, есть ли картинка в дисковом кеше
      if not awful.util.file_readable(cache) then
	 awful.util.mkdir(string.gsub(cache, "(.*)/.*$", "%1"))
	 -- загрузка картинки в дисковый кеш
	 local data = http.request(path)
	 if not data then return nil end
	 local f = io.open(cache, "w")
	 f:write(data)
	 f:flush()
	 f:close()
      end
      -- загрузка картинки в кеш в памяти
      data.image = capi.image(cache)
      data.image_path = path
   end
end

local function update(data)
   local request = "http://export.yandex.ru/weather/?city=" .. data.city
   local text = http.request(request)
   if not text then return end
   local xml = LuaXml.eval(text) or nil
   params = {"city", "country", "weather_type", "image2", "temperature", "pressure", "dampness"}
   for _, v in ipairs(params) do
      local param = xml:find(v)
      if param then
	 data.weather[v] = tostring(param[1]) or nil
      end
   end
   local text = ""
   text = text .. "температура: " .. data.weather.temperature

   image(data, data.weather.image2)
   local myimagebox = capi.widget({ type="imagebox", image = data.image })
   local mytextbox = capi.widget({ type="textbox", text = text })
   data.wibox.widgets = { mytextbox, myimagebox }

   log("weather", data)
end

function new(args)
   local args = args or {}
   local city = args.city or 27612 -- Moscow
   if tostring(tonumber(city)) ~= tostring(city) then return end
   data = {
      image = {},
      weather = {},
      city = tostring(city),
   }
   local w = capi.wibox(args)
   data.wibox = w
   local timer = timer({ timeout = args.timeout or 60 })
   timer:add_signal("timeout", function() update(data) end)
   timer:start()
   update(data)
   return w
end

setmetatable(_M, { __call = function(_, ...) return new(...) end })

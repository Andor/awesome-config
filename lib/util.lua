---------------------------------------------------------------------------
-- @author Andrew N Golovkov &lt;andrew.golovkov@gmail.com&gt;
-- @copyright 2009 Andrew N Golovkov
-- @release v0.1
---------------------------------------------------------------------------
local io = io
local os = os
local pairs = pairs
local tostring = tostring
local type = type
local setmetatable = setmetatable

module("lib.util")

-- Функция чтения файла целиком
function file_read(fname)
   local f = io.open(fname, "r")
   local data = f:read("*a")
   f:close()
   return data
end

function log(name, data)
   local text = ""
   local data = data or ""

   if type(data) == "table" then
      text = text .. "{" .. tostring(data):gsub("%s", "") .. ":"
      local k, v
      for k, v in pairs(data) do
	 text = text .. "[ " .. tostring(k) .. "=>" .. log(nil, v) .. " ]"
      end
      text = text .. "}"
   else
      text = text .. tostring(data)
   end

   if name == nil then return text end

   local name = tostring(name) or "awesome"
   log = io.open(os.getenv("HOME") .. "/" .. name .. ".log", "a")
   log:write(os.date("%H:%M:%S") .. ": " .. text .. ";\n")
   log:close()
end

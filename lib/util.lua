---------------------------------------------------------------------------
-- @author Andrew N Golovkov &lt;andrew.golovkov@gmail.com&gt;
-- @copyright 2009 Andrew N Golovkov
-- @release v0.1
---------------------------------------------------------------------------
local io = io
local os = os
local pairs = pairs
local tostring = tostring
local string = string
local type = type
local setmetatable = setmetatable

module("lib.util")

-- Функция чтения файла целиком
function file_read(fname)
   local f = io.open(fname, "r")
   if not f then return nil end
   local data = f:read("*a")
   f:close()
   return data
end

-- Функция записи целиком в файл
function file_write(fname, data, params)
   if not data then return nil end
   local params = params or {}
   local mode = params.mode or "w"
   if params.mkdir then
      local dir = string.gsub(fname, "(.*)/.*$", "%1")
      os.execute("mkdir -p " .. dir)
   end
   local f = io.open(fname, mode)
   if not f then return nil end
   f:write(data)
   f:flush()
   f:close()
end

-- Функция ведения лога
function log(name, data)
   local text = ""
   local data = data or ""
   local log = log -- for recursion

   if type(data) == "table" then
      text = text .. "{" .. tostring(data):gsub("%s", "") .. ":"
      local k, v
      for k, v in pairs(data) do
	 text = text .. "[ " .. tostring(k) .. "=>" .. log(nil, v) .. " ]" -- recursion
      end
      text = text .. "}"
   else
      text = text .. tostring(data)
   end

   if name == nil then return text end -- exit from recursion

   local name = tostring(name) or "log"
   fname = os.getenv("HOME") .. "/.awesome-" .. name .. ".log"
   text = os.date("%H:%M:%S") .. ": " .. text .. ";\n"
   return file_write(fname, text, { mode = "w" })
end

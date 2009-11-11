---------------------------------------------------------------------------
-- @author Stiletto &lt;blasux@blasux.ru&gt;
-- @copyright 2009 Stiletto
-- @release v0.1
-- @license WTFPL ( http://sam.zoy.org/wtfpl/COPYING )
---------------------------------------------------------------------------
local setmetatable = setmetatable
local awful = awful
local mouse = awful.mouse

local os = os
local math = require('math')
local text = require('lib.widget.text')

module('lib.widget.fuckingclock')


local function dec2bin(c)
    local s=""
    while c>0 do
	s=(c%2) .. s
	c=math.floor(c/2)
    end
    return s
end

local function padleft(str,sym,len)
    while #str < len do
	str=sym..str
    end
    return str
end

local function lamerizebin(s)
    local rets = ""
    local nums = "WG8421"
    for i = #s,1,-1 do
	if s:sub(i,i) == "1" then
	    rets=nums:sub(i,i)..rets
	else
	    rets = s:sub(i,i)..rets
	end
    end
    return rets
end

local function colorizebin(s,a)
    local rets = ""
    local cols = { "cyan", "red", "green", "orange", "white", "white" }
    for i = 1,#s,1 do
	if not (s:sub(i,i) == "0") then
	    if a == nil then
		rets=rets.."<span color='white'>"..s:sub(i,i).."</span>"
	    else
		rets=rets.."<span color='"..cols[i].."'>"..s:sub(i,i).."</span>"
	    end
	else
	    rets = rets..s:sub(i,i)
	end
    end
    return rets
end

--- Эта функция выдает строчку с подписаными разрядами WG8421, для установки в текстовый виджет awesome
-- @return Строчка времени в виде WG8421
local function gettimel()
    local dt = os.date("*t")
    return colorizebin(lamerizebin(padleft(dec2bin(dt.hour),'0',6))) .. " : " .. colorizebin(lamerizebin(padleft(dec2bin(dt.min),'0',6)))
end

--- Эта функция выдает строчку с раскрашенными разрядами, для установки в текстовый виджет awesome
-- @return Строчка времени в цветном бинарном виде
local function gettimec()
    local dt = os.date("*t")
    return colorizebin(padleft(dec2bin(dt.hour),'0',6),1) .. " : " .. colorizebin(padleft(dec2bin(dt.min),'0',6),1)
end

--- Функция обновления содержимого виджета часов.
-- @return Строка. Дата + время. Время двоичное, раскрашенное. Не хватает гибкости, да?
local function update()
    return os.date(" %a %b %d, ")..gettimec()
end

--- Функция, делающая наш няшненький виджет с часами
-- @param args Таблица аргументов. Пока единственное что можно настроить - timeout
-- @return Виджет двоичных часов
function new(args)
    local args = args or {}
    local mytimeout = args.timeout or 60
    local widget = text.new({ timeout = mytimeout, update_function = update })
    return widget
end

setmetatable(_M, { __call = function(_, ...) return new(...) end })

-- vim: filetype=lua:expandtab:shiftwidth=4:tabstop=8:softtabstop=4:encoding=utf-8:textwidth=80
---------------------------------------------------------------------------
-- @author Stiletto &lt;blasux@blasux.ru&gt;
-- @copyright 2010 Stiletto
-- @release v0.1
-- @license GPLv3
--   (Потому что блядская вирусность GPL не дает порелизить
--    мне этот скрипт под WTFPL ( http://sam.zoy.org/wtfpl/COPYING ) т.к.
--    он использует библиотеки Андора, которые под GPLv3.)
---------------------------------------------------------------------------
local setmetatable = setmetatable
local awful = awful
local mouse = awful.mouse

local os = os
local math = require('math')
local text = require('lib.widget.text')

module('lib.widget.jaclock')

local janum = {"零","一","二","三","四","五","六","七","八","九"}

function arabic2jap(c)
    local s=""
    if (c==0) or not (c%10==0) then
        s=janum[c%10+1]
    end
    if c>=10 then
	s=janum[math.floor(c%100/10)+1].."十"..s
    end
    return s
end
    
local function padleft(str,sym,len)
    while #str < len do
	str=sym..str
    end
    return str
end

--- Эта функция выдает строку готовую для установки в часы
-- @return Строка времени
local function update()
    local dt = os.date("*t")
    return "<span font='Unifont'><span color='white'> "..arabic2jap(dt.hour).."</span>時<span color='white'>"..arabic2jap(dt.min).."</span>分 </span>"
end

--- Функция, делающая наш няшненький виджет с часами
-- @param args Таблица аргументов. Пока единственное что можно настроить - timeout
-- @return Виджет канзи-часов
function new(args)
    local args = args or {}
    local mytimeout = args.timeout or 60
    local widget = text.new({ timeout = mytimeout, update_function = update })
    return widget
end

setmetatable(_M, { __call = function(_, ...) return new(...) end })

-- vim: filetype=lua:expandtab:shiftwidth=4:tabstop=8:softtabstop=4:encoding=utf-8:textwidth=80
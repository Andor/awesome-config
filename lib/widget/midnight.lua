---------------------------------------------------------------------------
-- @author Stiletto &lt;blasux@blasux.ru&gt;
-- @copyright 2010 Stiletto
-- @release v0.1
-- @license GPLv3
--
-- Midnight timer
--
-- СРАНЫЙ НОРКОМАН НАПИСАЛ ЕЩЁ ЧАСЫ
-- В общем суть токова: это даже не часы, это обратный отсчет до полуночи.
-- Он сделан чтобы всяких идиотов заставлять выпрямить свой режим.
-- Если до полуночи менее 2 часов, таймер становится оранжевым.
-- Если более 19 - тоже.
-- В промежутке между 23 и 01 таймер красный и мигает.
-- Он как бы говорит нам: ИДИ СПАТЬ СУКА!
-- 
---------------------------------------------------------------------------
local setmetatable = setmetatable
local awful = awful
local mouse = awful.mouse

local os = os
local math = require('math')
local text = require('lib.widget.text')
fuck=false

local function padleft(str,sym,len)
    while #str < len do
    str=sym..str
    end
    return str
end

module('lib.widget.midnight')

--- Эта функция выдает строку готовую для установки в часы
-- @return Строка времени
local function update()
    local dt = os.date("*t")
    local color = "green"
    if ((dt.hour)>=22) or ((dt.hour)<=4) then
        -- if (((dt.hour)==23) and ((dt.min)>30)) or (((dt.hour)==0) and ((dt.min)<30)) then
        if ((dt.hour)==23) or ((dt.hour)==0) then
            color = "red"
        else
            color = "orange"
        end
    end
    if color=="red" then
        fuck = not fuck
    else
        fuck = false
    end
    if fuck then
        return padleft(" "," ",2*2+2)
    else
        return "<span color='"..color.."'> "..padleft((23-dt.hour).."",'0',2)..
            "</span>:<span color='"..color.."'>"..padleft((59-dt.min).."",'0',2).."</span>"
            --..
            --":<span color='"..color.."'>"..padleft((59-dt.sec).."",'0',2).."</span>"
    end
end

--- Функция, делающая наш няшненький виджет с часами
-- @param args Таблица аргументов. Пока единственное что можно настроить - timeout
-- @return Виджет часов с отсчетом до полуночи
function new(args)
    local args = args or {}
    local mytimeout = args.timeout or 1
    local widget = text.new({ timeout = mytimeout, callback = update })
    return widget
end

setmetatable(_M, { __call = function(_, ...) return new(...) end })

-- vim: filetype=lua:expandtab:shiftwidth=4:tabstop=8:softtabstop=4:encoding=utf-8:textwidth=80

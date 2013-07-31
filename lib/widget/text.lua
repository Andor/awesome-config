---------------------------------------------------------------------------
-- @author Andrew N Golovkov &lt;andrew.golovkov@gmail.com&gt;
-- @copyright 2009 Andrew N Golovkov
-- @release v0.1
---------------------------------------------------------------------------

local setmetatable = setmetatable
local type = type
local textbox = require('wibox.widget.textbox')
local capi = { timer = timer }

local text = { mt = {} }

--- Создаёт текстовый виджет с опциональным автообновлением.
-- @param args Standard arguments for textbox widget.
-- @param update_finction Функция обновления текста виджета.
-- @param timeout Таймаут обновления. По-умолчанию 10.
-- @return Виджет.
function text.new(args)
    local args = args or {}
    local timeout = args.timeout or 60

    local w = textbox()

    if args.callback and type(args.callback) == "function" then
       local update = args.callback
       local timer = capi.timer { timeout = timeout }
       timer:connect_signal("timeout", function() w:set_markup( update() ) end)
       timer:start()
       timer:emit_signal("timeout")
    end

    return w
end

function text.mt:__call(...)
    return text.new(...)
end


-- setmetatable(_M, { __call = function(_, ...) return new(...) end })
return setmetatable(text, text.mt)

-- vim: filetype=lua:expandtab:shiftwidth=4:tabstop=8:softtabstop=4:encoding=utf-8:textwidth=80

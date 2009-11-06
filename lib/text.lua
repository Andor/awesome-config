---------------------------------------------------------------------------
-- @author Andrew N Golovkov &lt;andrew.golovkov@gmail.com&gt;
-- @copyright 2009 Andrew N Golovkov
-- @release v0.1
---------------------------------------------------------------------------

local setmetatable = setmetatable
local type = type
local capi = { widget = widget,
               timer = timer }

--- Text widget.
module("awful.widget.text")

--- Create a textwidget widget. It draws text it is in a textbox.
-- @param args Standard arguments for textbox widget.
-- @param format The time format. Default is " %a %b %d, %H:%M ".
-- @param timeout How often update the time. Default is 60.
-- @return A textbox widget.
function new(args)
    local args = args or {}
    local timeout = args.timeout or 60

    args.type = "textbox"
    local w = capi.widget(args)

    if args.update_function and type(args.update_function) == "function" then
       local update = args.update_function
       local timer = capi.timer { timeout = timeout }
       w.text = update()
       timer:add_signal("timeout", function() w.text = update() end)
       timer:start()
    end

    return w
end

setmetatable(_M, { __call = function(_, ...) return new(...) end })

-- vim: filetype=lua:expandtab:shiftwidth=4:tabstop=8:softtabstop=4:encoding=utf-8:textwidth=80

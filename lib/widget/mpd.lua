---------------------------------------------------------------------------
-- @author Andrew N Golovkov &lt;andrew.golovkov@gmail.com&gt;
-- @copyright 2009 Andrew N Golovkov
-- @release v0.1
---------------------------------------------------------------------------
local setmetatable = setmetatable
local capi = { widget = capi.widget,
	       timer = capi.timer,
	       mouse = capi.mouse }
local awful = awful
local mouse = awful.mouse

function new(args)
   local w = capi.widget()
--   w.add_signal("mouse:enter", )
   return w
end

setmetatable(_M, { __call = function(_, ...) return new(...) end })

-- vim: filetype=lua:expandtab:shiftwidth=4:tabstop=8:softtabstop=4:encoding=utf-8:textwidth=80
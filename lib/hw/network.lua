local util = require("lib.util")
local tonumber, tostring = tonumber, tostring

-- функция получения текста трафика на интерфейсе
function get_interface_data(interface)
   local int = tostring(interface) or "eth0"

   local rx = util.file_read("/sys/class/net/" .. int .. "/statistics/rx_bytes")
   local tx = util.file_read("/sys/class/net/" .. int .. "/statistics/tx_bytes")

   local text = "[" .. int .. ":"
   local number, mod = "None", ""
   if tx and rx then
      number = (tonumber(rx)+tonumber(tx))
      if number > 10*1024 then
	 number = number/1024
	 if number > 10*1024 then
	    number = number/1024
	    if number > 10*1024 then
	       number = number/1024
	       mod = "g"
	    else
	       mod = "m"
	    end
	 else
	    mod = "k"
	 end
      else
	 mod = "b"
      end
      number = math.floor(number)
   end
   text = text .. number .. mod .. "]"
   data = {
      int = int,
      tx = tx,
      rx = rx,
      sum = number,
      mod = mod,
      text = text }
   return data
end

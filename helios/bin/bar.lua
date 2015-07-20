function slide(msg)
	local s = msg
	local l = s:len()
	for i = 0,l do
		term.setCursorPos(1,1)
		term.write(s:sub(l-i,l))
		sleep(.1)
	end
	sleep(2)
	for i = l,0,-1 do
		term.clear()
		term.setCursorPos(1,1)
		term.write(s:sub(l-i,l))
		sleep(.1)
	end
	term.clear()
end

local seen = {}
local notifications = {}

daemon.registerDaemon("Notification Receiver","Receives all the notifications",function()
	while true do
		local evt = {os.pullEvent()}
		if(evt[1] == "notification") then
			table.insert(notifications,evt[2])
		end
	end
end)

while true do
	if(#notifications>0) then
		slide(notifications[1])
		table.insert(seen,notifications[1])
		table.remove(notifications,1)
	end
	sleep(0)
end


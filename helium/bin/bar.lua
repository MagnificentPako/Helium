local messages = {
	"Welcome to Helium!",
	"How are you?",
	"This is not an OS, you know?",
	"I like trains.",
	"Helium doesn't react."
}

function slide(msg)
	local s = msg
	local l = s:len()
	for i = 0,l do
		term.setCursorPos(1,1)
		term.write(s:sub(l-i,l))
		sleep(0)
	end
	sleep(2)
	for i = l,0,-1 do
		term.clear()
		term.setCursorPos(1,1)
		term.write(s:sub(l-i,l))
		sleep(0)
	end
	term.clear()
end

local seen = {}
local notifications = {}

term.setBackgroundColor(colors.gray)
term.setTextColor(colors.white)
term.clear()

daemon.registerDaemon("Notification Receiver","Receives all the notifications",function()
	while true do
		local evt = {os.pullEvent()}
		if(evt[1] == "notification") then
			if(evt[2] ~= string.rep(" ",#evt[2])) then 
				table.insert(notifications,evt[2])
			end
		end
	end
end)

notifications[1] = messages[math.random(#messages)]

while true do
	if(#notifications>0) then
		slide(notifications[1])
		table.insert(seen,notifications[1])
		table.remove(notifications,1)
	end
	coroutine.yield()
end


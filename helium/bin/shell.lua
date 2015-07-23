term.setBackgroundColor(colors.lightGray)
term.clear()
term.setCursorPos(1,1)
term.setTextColor(colors.black)
utils.cWrite("Helium",term.current())
print()
print()

local his = {}
while true do
	term.setTextColor(colors.black)
	term.setBackgroundColor(colors.lightGray)
	write">"
	local r	= utils.read(term.current(),nil,his,colors.black,colors.white)
	table.insert(his,r)
	local str = table.concat(r,"")
	if(str == "toggle") then
		redirector.toggle("Bar")
	end
	os.queueEvent("notification",str)
	print()
end
while true do
	local evt = {os.pullEvent("mouse_click")}
	term.setBackgroundColor(evt[2] == 1 and colors.orange or colors.green)
	term.setCursorPos(evt[3],evt[4])
	term.write(" ")
end
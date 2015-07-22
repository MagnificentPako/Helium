function lookupify(t)
	local tt = {}
	for k,v in pairs(t) do
		tt[v] = true
	end
	return tt
end

function cWrite(text,buffer)
	b = buffer
	local x,y = b.getCursorPos()
	local w,h = b.getSize()
	b.setCursorPos((w/2)-(#text/2),y)
	b.write(text)
end
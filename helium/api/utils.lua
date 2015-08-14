function lookupify(t)
	local tt = {}
	for k,v in pairs(t) do
		tt[v] = true
	end
	return tt
end

function copyTable(t)
	local tt = {}
	for k,v in pairs(t) do
		tt[k] = v
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

function readonly(tbl)
	local t = copyTable(tbl)
	setmetatable(t,{__newindex = function() error("nope") end,__metatable={"false"}})
	return t
end

function read(buffer,mask,hist,normal,selected)
	local term = buffer
	local continue = true
	local stopKey = keys.enter
	local W,H = term.getSize()
	local mask = mask and mask:sub(1,1) or nil
	local history = hist and hist or {}
	local normal = normal or colors.black
	local selected = selected or colors.gray
	local historyPointer
	local cursor = 1
	local str = {}
	local lastLength = 0
	local sX,sY = term.getCursorPos()
	local function copy(t)
		local tt = {}
		for k,v in pairs(t) do tt[k] = v end 
		return tt
	end
	local function makeASapce(t,p)
		local o = copy(t)
		for i = #t,p,-1 do
			o[i+1] = o[i]
		end
		o[p] = nil
		return o
	end
	local function redraw()
		term.setCursorPos(sX,sY)
		term.write(string.rep(" ",lastLength))
		term.setCursorPos(sX,sY)
		if(#str==0) then
			term.setTextColor(selected)
			if(continue) then
				term.write("_")
			else
				term.write(" ")
			end
		else
			for k,v in pairs(str) do
				local sel = k == cursor
				term.setTextColor(sel and selected or normal)
				if(mask) then
					term.write(mask)
				elseif(v == " " and sel) then
					term.write"_"
				else
					term.write(v)
				end
			end
		end
		lastLength = W
	end
	redraw()
	while continue do
		local evt = {os.pullEvent()}
		if(evt[1] == "char") then
			if(cursor < #str) then
				str = makeASapce(str,cursor)
				str[cursor] = evt[2]
				cursor = cursor+1
			else
				str[#str+1] = evt[2]
				cursor = #str
			end
			redraw()
		elseif(evt[1] == "key") then
			if(evt[2] == 14) then
				table.remove(str,cursor)
				cursor = cursor-1
				if(cursor>#str) then cursor = #str end
				if(cursor<1) then cursor = 1 end
				redraw()
			elseif(evt[2] == keys.left) then
				if(cursor > 1) then cursor = cursor-1 end
				redraw()
			elseif(evt[2] == keys.right) then
				if(cursor < #str) then cursor = cursor+1 end
				redraw()
			elseif(evt[2] == keys.enter) then
				cursor = #str+1
				continue = false
				redraw()
			elseif(evt[2] == keys.up or evt[2] == keys.down) then
				if(history) then
					if(evt[2] == keys.up) then
						if(historyPointer == nil) then
							if(#history > 0) then
								historyPointer = #history
							end
						elseif(historyPointer > 1) then
							historyPointer = historyPointer - 1 
						end
					elseif(evt[2] == keys.down) then
						if(historyPointer == #history) then
							historyPointer = nil
						elseif(historyPointer ~= nil) then
							historyPointer = historyPointer + 1 
						end
					end
					if(historyPointer) then
						str = history[historyPointer]
						cursor = #str
					else
						str = {}
						cursor = 0
					end
				end
				redraw()
			end
		end
	end
	return str
end
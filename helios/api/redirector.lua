local programs = {}

local userinput = {"char","key","mouse_click","mouse_drag"}
userinput = utils.lookupify(userinput)

function addProgram(path,buffer,name)
	assert(fs.exists(path),"Nope.")
	local f = loadstring("os.run({},'"..path.."')")
	local co = coroutine.create(f)
	programs[name] = {name=name,routine=co,buffer=buffer,enabled=true,filter=nil}
end

function toggle(name)
	programs[name].enabled = not programs[name].enabled
end

function copy(t)
	local tt = {}
	for k,v in pairs(t) do tt[k] = v end
	return tt
end

function run()
	while true do
		local evt = {coroutine.yield()}
		local e = copy(evt)
		for k,v in pairs(programs) do
			if(evt[1] == "mouse_click" or evt[1] == "mouse_drag") then
				local x,y = v.buffer:getPosition()
				e[3] = evt[3]-x+1
				e[4] = evt[4]-y+1
			end
			if(v.enabled) then
				if(evt[1] == "terminate" or v.filter == evt[1] or v.filter == nil) then
					term.redirect(v.buffer.tRedirect)
					local ok,filter = coroutine.resume(v.routine,unpack(e))
					v.filter = filter
				end
			end
		end
	end
end
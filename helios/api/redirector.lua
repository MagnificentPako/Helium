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

function run()
	while true do
		local evt = {coroutine.yield()}
		for k,v in pairs(programs) do
			if(v.enabled) then
				if(evt[1] == "terminate" or v.filter == evt[1] or v.filter == nil) then
					term.redirect(v.buffer)
					local ok,filter = coroutine.resume(v.routine,unpack(evt))
					v.filter = filter
				end
			end
		end
	end
end
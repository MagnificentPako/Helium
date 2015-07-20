local programs = {}

local userinput = {"char","key","mouse_click","mouse_drag"}
userinput = utils.lookupify(userinput)

function addProgram(path,buffer,name)
	assert(fs.exists(path),"Nope.")
	local f = loadfile(path)
	local co = coroutine.create(f)
	programs[name] = {name=name,routine=co,buffer=buffer,visible=true,enabled=true}
end

function toggleVisibility(name)
	programs[name].visible = not programs[name].visible
end

function toggle(name)
	programs[name].enabled = not programs.name.enabled
end

function run()
	while true do
		local evt = {coroutine.yield()}
		for k,v in pairs(programs) do
			term.redirect(v.buffer)
			coroutine.resume(v.routine,unpack(evt))
		end
	end
end
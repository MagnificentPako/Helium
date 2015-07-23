local function loadAPI(path,name)
	local handle = fs.open(path,"r")
	local content = handle.readAll()
	handle.close()
	local f = loadstring(content)
	local env = {}
	setmetatable(env,{__index=_G})
	setfenv(f,env)
	f()
	_G[name] = env
end

loadAPI("helios/api/utils.lua","utils")

loadAPI("helios/api/taskmanager.lua","taskmanager")

loadAPI("helios/api/daemon.lua","daemon")

loadAPI("helios/api/buffer.lua","buffer")
loadAPI("helios/api/screenHandler.lua","screenHandler")

loadAPI("helios/api/redirector.lua","redirector")

local shellBuffer = screenHandler.createRedirectBuffer(51,18,1,2)

local barBuffer = screenHandler.createRedirectBuffer(51,1,1,1)

redirector.addProgram("helios/bin/mousetest.lua",shellBuffer.buffer,"Shell")
redirector.addProgram("helios/bin/bar.lua",barBuffer.buffer,"Bar")

taskmanager.addRoutine(daemon.run)
taskmanager.addRoutine(screenHandler.run)
taskmanager.addRoutine(redirector.run)

taskmanager.run()

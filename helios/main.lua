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

local shellBuffer,_ = screenHandler.createRedirectBuffer(51,18,1,2)

local barBuffer,_ = screenHandler.createRedirectBuffer(51,1,1,1)
barBuffer.setBackgroundColor(colors.gray)
barBuffer.clear()

redirector.addProgram("helios/bin/shell.lua",shellBuffer,"Shell")
redirector.addProgram("helios/bin/bar.lua",barBuffer,"Bar")

taskmanager.addRoutine(daemon.run)
taskmanager.addRoutine(screenHandler.run)
taskmanager.addRoutine(redirector.run)

taskmanager.run()
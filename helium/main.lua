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

loadAPI("helium/api/utils.lua","utils")

loadAPI("helium/api/filesystem.lua","filesystem")

loadAPI("helium/api/taskmanager.lua","taskmanager")

loadAPI("helium/api/daemon.lua","daemon")

loadAPI("helium/api/buffer.lua","buffer")
loadAPI("helium/api/screenHandler.lua","screenHandler")

loadAPI("helium/api/redirector.lua","redirector")

filesystem.loadFilesystem("helium/api/filesystems/emulated.lua")

local barBuffer = screenHandler.createRedirectBuffer(51,1,1,1)
local shellBuffer = screenHandler.createRedirectBuffer(51,18,1,2)

redirector.addProgram("helium/bin/shell.lua",shellBuffer.buffer,"Shell")
redirector.addProgram("helium/bin/bar.lua",barBuffer.buffer,"Bar")

taskmanager.addRoutine(daemon.run)
taskmanager.addRoutine(screenHandler.run)
taskmanager.addRoutine(redirector.run)

taskmanager.run()

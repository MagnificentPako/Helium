local daemons = {}

function registerDaemon(name,description,func)
	local co = coroutine.create(func)
	daemons[name] = {desc = description, routine = co,enabled = true,filter = nil}
end

function disableDaemon(name)
	daemons[name].enabled = false
end

function enableDaemon(name)
	daemons[name].enabled = true
end

function getDaemons()
	return daemons
end

local alreadyRunning = false
function run()
	if(alreadyRunning) then error("A deamon handler is already running.",2) end
	alreadyRunning = true
	while true do
		local evt = {coroutine.yield()}
		for k,v in pairs(daemons) do
			if(v.enabled) then
				if(evt[1] == "terminate" or evt[1] == v.filter or v.filter == nil) then
					local ok, filter = coroutine.resume(v["routine"],unpack(evt))
					v.filter = filter
				end
			end
		end
	end
end
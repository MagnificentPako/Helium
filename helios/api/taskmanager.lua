local routines = {}

function addRoutine(f)
	local co = coroutine.create(f)
	routines[#routines+1] = {routine=co,filter=nil}
	return #routines
end

function removeRoutine(id)
	table.remove(routines,id)
end

local running = false

function run()
	if running then error("A taskmanager is already running",0) end
	os.queueEvent"q"
	running = true
	while true do
		local evt = {os.pullEvent()}
		for k,v in pairs(routines) do
			if(evt == "terminate" or v.filter == evt[1] or v.filter == nil) then
				local ok,filter = coroutine.resume(v.routine,unpack(evt))
				v.filter = filter
			end
		end
	end
end

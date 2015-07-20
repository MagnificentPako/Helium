local routines = {}

function addRoutine(f)
	local co = coroutine.create(f)
	routines[#routines+1] = co
	return #routines
end

function removeRoutine(id)
	table.remove(routines,id)
end

function run()
	os.queueEvent"q"
	while true do
		local evt = {os.pullEvent()}
		for k,v in pairs(routines) do
			coroutine.resume(v,unpack(evt))
		end
	end
end

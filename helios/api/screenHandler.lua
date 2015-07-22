local buffers = {}
local W,H = term.getSize()
local mainBuffer = buffer.new(W,H,1,1,term.native())

function createRedirectBuffer(w,h,x,y)
	local buf = buffer.new(w,h,x,y,mainBuffer.tRedirect)
	buffers[#buffers+1] = {buffer = buf,visible = true}
	local object = {id=#buffers,buffer=buf.tRedirect}
	return object
end

function setVisibility(id,vis)
	buffers[id].visible = vis
end

function render()
	for k,v in pairs(buffers) do
		if(v.visible) then
			v.buffer:render()
		end
	end
	mainBuffer:render()
end

function run()
	while true do 
		render()
		sleep(0)
	end
end
local needed = utils.lookupify({
	"isDir",
	"exists",
	"open",
	"makeDir",
	"list",
	"move",
	"copy",
	"delete"
})

local filesystems = {}

function loadFilesystem(path)
	local env = {}
	setmetatable(env,{__index=_G})
	local f = loadfile(path)
	setfenv(f,env)
	local ok, err = pcall(f)
	if(not ok) then error(err,1) end
	for k,v in pairs(needed) do
		if(not env[k]) then
			term.setTextColor(colors.red)
			print("At least "..k.." is missing.")
			error("File system corrupt.",0)
		end
	end
end
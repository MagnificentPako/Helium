local system = {}

print(utils.readonly({}))

function open(file, mode)
	if(mode == "w") then
		return utils.readonly({
		content = {}
		closed = false
		writeLine = function(text)
			if(closed) then error("Handle already closed.") end
			table.insert(content,line)
		end,
		flush = function()
			if(closed) then error("Handle already closed.") end
			system[file] = content
		end,

	})
	elseif(mode == "r") then
		return {

	}
	end
end

function exists()

end

function open()

end

function makeDir()
 return false
end

function list()
	local l = {}
	for k,_ in pairs(system) do
		table.insert(l,k)
	end
	return l
end

function move()

end

function copy()

end

function delete(file)
	system[file] = nil
end

function isDir()
	return false
end
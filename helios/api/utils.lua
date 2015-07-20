function lookupify(t)
	local tt = {}
	for k,v in pairs(t) do
		tt[v] = true
	end
	return tt
end
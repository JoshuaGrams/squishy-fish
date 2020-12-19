return function(obj, key, dt)
	if obj[key] then
		obj[key] = obj[key] - dt
		return obj[key] <= 0
	end
end


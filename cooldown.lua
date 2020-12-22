return function(obj, key, dt)
	if obj[key] then
		obj[key] = obj[key] - dt
		if obj[key] <= 0 then
			obj[key] = nil
			return true
		end
	end
end


local function drawGroup(group, x, y, r, R)
	local px, py = player:center()
	local R2 = R*R
	local sc = r/R
	for _,a in ipairs(group) do
		if not a.bullet then
			local ax, ay = a:center()
			local dx, dy = ax - px, ay - py
			local d2 = dx*dx + dy*dy
			if d2 <= R2 then
				love.graphics.circle('fill', x + dx*sc, y + dy*sc, 3)
			end
		end
	end
end

function MiniMap(x, y, r, R)
	local w, h = vw*r/R, vh*r/R
	love.graphics.setColor(0.5, 0.5, 0.5, 0.3)
	love.graphics.circle('fill', x, y, r)
	love.graphics.rectangle('fill', x - w/2, y - h/2, w, h)
	love.graphics.setColor(0.2, 0.6, 0.3, 0.5)
	drawGroup(group.friends, x, y, r, R)
	love.graphics.setColor(0.8, 0.3, 0.2, 0.5)
	drawGroup(group.enemies, x, y, r, R)
end

return MiniMap

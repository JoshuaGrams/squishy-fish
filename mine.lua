local Actor = require 'actor'
local cooldown = require 'cooldown'

local Mine = Actor:extend()

function Mine.set(S, x, y)
	local rnd = math.random()
	local sz = 75 + rnd*(180-75)
	Actor.set(S, x, y, sz, sz, I.mine)
	S.health = 4
	S.R = 250 + rnd*(530-250)
	S.damage = roundTo(randomIn(1.5, 3.5), 0.5)
	S.fuseDelay = 1.5
	S.scanEvery = 0.2
	S.scanTime = S.scanEvery
end

function Mine.update(S, dt)
	Actor.update(S, dt, true)
	local enemyNearby = false
	if cooldown(S, 'scanTime', dt) then
		S.scanTime = S.scanEvery
		local N, dx, dy = nearest(S)
		enemyNearby = N and dx*dx + dy*dy <= S.R*S.R and N.group ~= S.group
	end
	local badlyDamaged = S.health and S.health <= 2
	if enemyNearby or badlyDamaged then
		S.health, S.scanTime = nil, nil
		S.explodeAfter = S.fuseDelay
	elseif cooldown(S, 'explodeAfter', dt) then
		for _,a in ipairs(nearby(S, S.R)) do
			if a.health then
				a.health = a.health - S.damage
			end
		end
		S.group = nil
	end
end

function Mine.draw(S)
	if S.explodeAfter then
		local c = 0.5 + 0.5*math.cos(4*math.pi * S.explodeAfter/S.fuseDelay)
		love.graphics.setColor(c, 0.3*c, 0.3*c, 0.3)
		local x, y = S:center()
		love.graphics.circle('fill', x, y, S.R)
	end
	Actor.draw(S)
end

return Mine

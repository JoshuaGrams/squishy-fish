local Actor = require 'actor'
local cooldown = require 'cooldown'
local Effects = require 'effects'

local Patroller = Actor:extend()

local function randomDirection(dirs)
	local u = math.random()
	local n = 1 + math.floor(#dirs * (1 - u*u))
	local dir = table.remove(dirs, n)
	table.insert(dirs, dir)
	return dir
end

local function directionTo(a, b)
	if not b then return end
	local ax, ay = a:center()
	local bx, by = b:center()
	local dx, dy = bx - ax, by - ay
	if math.abs(dy) > math.abs(dx) then dx = 0 else dy = 0 end
	local dir = 1 + math.floor(0.5 + math.atan2(dy, dx) / (math.pi/2)) % 4
	return dir
end

function Patroller.set(S, x, y)
	Actor.set(S, x, y, 180, 74, I.patroller)
	S.dirs = {1, 2, 3, 4}
	S.dir = randomDirection(S.dirs)
	S.hitScale = 0.75
	S.health = 2.5
	S.turnEvery, S.shootEvery = 3, 5
	S.turnTime, S.shootTime = S.turnEvery, S.shootEvery
end

function Patroller.update(S, dt)
	if cooldown(S, 'turnTime', dt) then
		S.turnTime = S.turnEvery
		S.dir = nil
		if math.random() < 0.5 then
			local N, bdx, bdy = nearest(S)
			if N then S.dir = directionTo(S, N) end
			if bdx*bdx + bdy*bdy < 500*500 then
				S.dir = S.dir + (math.random() < 0.5 and 1 or 3)
				S.dir = 1 + (S.dir-1)%4
			end
		end
		if not S.dir then S.dir = randomDirection(S.dirs) end
		local speed = 150
		local th = 2*math.pi * (S.dir-1)/4
		S.vx, S.vy = speed*math.cos(th), speed*math.sin(th)
	end
	Actor.update(S, dt)

	local opponent, dx, dy = nearest(S, false)
	local near= 1000
	if opponent and dx*dx + dy*dy < near*near then
		if cooldown(S, 'shootTime', dt) then
			S.shootTime = S.shootEvery
			local x, y = S:center()
			local bullet = Actor(x, y, 80, 80, I.greenBall)
			local scale = 1 / math.sqrt(dx*dx + dy*dy)
			local speed = 400
			bullet.bullet = true
			bullet.vx, bullet.vy = dx*scale*speed, dy*scale*speed
			bullet.lifetime = 7.5
			bullet.owner = S
			bullet.hit = Effects.hurt
			bullet.hitScale = 0.6
			bullet.damage = 1.5
			addTo(bullet, S.group)
		end
	end
end

return Patroller

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

function Patroller.set(S, x, y)
	Actor.set(S, x, y, 180, 74, I.patroller)
	S.dirs = {1, 2, 3, 4}
	S.dir = randomDirection(S.dirs)
	S.hitScale = 0.75
	S.health = 2
	S.turnEvery, S.shootEvery = 3, 5
	S.turnTime, S.shootTime = S.turnEvery, S.shootEvery
end

function Patroller.update(S, dt)
	if cooldown(S, 'turnTime', dt) then
		S.turnTime = S.turnEvery
		S.dir = randomDirection(S.dirs)
		local speed = 150
		local th = 2*math.pi * (S.dir-1)/4
		S.vx, S.vy = speed*math.cos(th), speed*math.sin(th)
	end
	Actor.update(S, dt, true)

	local px, py = player:center()
	local x, y = S:center()
	local dx, dy = px - x, py - y
	local near = 1000
	local d2 = dx*dx + dy*dy
	if d2 < near*near then
		if cooldown(S, 'shootTime', dt) then
			S.shootTime = S.shootEvery
			local bullet = Actor(x, y, 80, 80, I.greenBall)
			local scale = 1 / math.sqrt(d2)
			local speed = 400
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

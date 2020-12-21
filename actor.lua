local cooldown = require 'cooldown'
local Object = require 'base-class'
local Actor = Object:extend()

local TURN = 2*math.pi
local abs, floor = math.abs, math.floor
local atan2 = math.atan2

function Actor.set(S, x, y, w, h, img)
	S.img = img
	S.color = {1,1,1}
	S.r = {x+w/2, y+h/2, x-w/2, y-h/2}
	S.dir, S.xScale = 1, 1
	S.rotateHitBox = true
end

function Actor.center(S)
	return 0.5*(S.r[1]+S.r[3]), 0.5*(S.r[2]+S.r[4])
end

function Actor.size(S, hitBox)
	local w, h = S.r[1] - S.r[3], S.r[2] - S.r[4]
	if hitBox then
		if S.hitScale then
			w, h = w * S.hitScale, h * S.hitScale
		end
		if S.rotateHitBox and S.dir % 2 == 0 then w, h = h, w end
	end
	return w, h
end

function Actor.setPos(S, x, y)
	local x0, y0 = S:center()
	local dx, dy = x - x0, y - y0
	S.r[1], S.r[3] = S.r[1] + dx, S.r[3] + dy
	S.r[2], S.r[4] = S.r[2] + dy, S.r[4] + dy
end

function Actor.overlaps(a, b)
	local ax, ay = a:center()
	local aw, ah = a:size(true)
	local bx, by = b:center()
	local bw, bh = b:size(true)
	local dx, dy = ax - bx, ay - by
	local halfW, halfH = 0.5*(aw+bw), 0.5*(ah+bh)
	local hSep = dx > halfW or dx < -halfW
	local wSep = dy > halfH or dy < -halfH
	return not (hSep or wSep)
end

function Actor.update(S, dt, debug)
	if S.vx and S.vy then
		S.r[1], S.r[3] = S.r[1] + dt*S.vx, S.r[3] + dt*S.vx
		S.r[2], S.r[4] = S.r[2] + dt*S.vy, S.r[4] + dt*S.vy
		if abs(S.vx) > 0.1 or abs(S.vy) > 0.1 then
			S.dir = 1 + floor(0.5 + atan2(S.vy, S.vx) / (TURN/4))
			S.xScale = 1
			if S.dir == 3 then S.dir, S.xScale = 1, -1 end
		end
	end
	if S.lifetime and cooldown(S, 'lifetime', dt) then
		S.lifetime, S.dead = nil, true
	end
	if S.health and S.health <= 0 then
		S.dead = true
	end
end

function Actor.draw(S)
	love.graphics.setColor(S.color)
	local x, y = S:center()
	local w, h = S:size()
	local th = TURN * (S.dir - 1)/4
	local iw, ih = S.img:getDimensions()
	love.graphics.draw(S.img, x, y, th, w/iw*S.xScale, h/ih, w/2, h/2)
end

return Actor

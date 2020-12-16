local Trail = require 'trail'
local Object = require 'base-class'
local Player = Object:extend()

local sqrt = math.sqrt
local abs, floor = math.abs, math.floor
local min, max = math.min, math.max
local function clamp(x, lo, hi) return max(lo, min(x, hi)) end

function Player.set(P, x, y, w, h)
	P.area, P.maxAspect = w*h, w/h
	P.aspect = 1
	w, h = P:size()
	P.r = {x+w, y+h, x, y}  -- clockwise: right, bottom, left, top
	P.speed, P.maxSpeed = 0, 800
	P.tAccel, P.tDecay = 0.175, 0.8
	P.accel = 0
	P.dir = 1
	P:computeAcceleration()
	local spot = love.graphics.newImage('assets/particle.png')
	P.trail = Trail(spot, 1.8, {0.75, 0.25, 0.95})
end

function Player.size(P)
	local w = floor(0.5 + sqrt(P.area * P.aspect))
	local h = floor(0.5 + P.area / w)
	return w, h
end

-- returns short, long
function Player.limits(P)
	return sqrt(P.area/P.maxAspect), sqrt(P.area*P.maxAspect)
end

function Player.center(P)
	return 0.5*(P.r[1]+P.r[3]), 0.5*(P.r[2]+P.r[4])
end

local adjacent = {2, 3, 4, 1}
local opposite = {3, 4, 1, 2}

Player.opposite, Player.adjacent = opposite, adjacent

function Player.directionSign(P)
	return P.r[P.dir] < P.r[opposite[P.dir]] and -1 or 1
end

function Player.side(P, dir)
	local r = {unpack(P.r)}
	r[opposite[dir]] = r[dir]
	return r
end

function Player.length(P)
	local i = 2 - P.dir%2
	return P.r[i] - P.r[i+2]
end

function Player.width(P)
	local i = 1 + P.dir%2
	return P.r[i] - P.r[i+2]
end

function Player.reshape(P, length)
	length = clamp(length, P:limits())
	-- Adjust the back.
	local sign = P.dir > 2 and -1 or 1
	P.r[opposite[P.dir]] = P.r[P.dir] - sign * length
	-- Adjust the sides.
	local side = 1 + P.dir%2
	local center = 0.5 * (P.r[side] + P.r[side+2])
	local halfWidth = 0.5 * P.area/length
	P.r[side] = center + halfWidth
	P.r[side+2] = center - halfWidth
	return length
end

function Player.moveFront(P, amount)
	local sign = P.dir > 2 and -1 or 1
	P.r[P.dir] = P.r[P.dir] + sign * amount
end

function Player.stretch(P, stretch, motion)
	local length = P:length() + stretch
	-- If stretching, move the front (otherwise we're squishing,
	-- so the front stays the same).
	if stretch > 0 then P:moveFront(motion or stretch) end
	-- Move the other three sides to match the new length.
	P:reshape(length)
end

function Player.move(P, amount)
	local length = P:length()
	P:moveFront(amount)
	P:reshape(length)
end

function Player.turnTo(P, dir)
	P.dir = 1 + (dir-1)%4
	P.speed = 0
end

function Player.computeSpeed(P)
	local length = P:length()
	local _, long = P:limits()
	local square = sqrt(P.area)
	P.speed = max(0, P.maxSpeed * (length - square) / (long - square))
end

function Player.decayShape(P, dt, dir)
	local length = P:length()
	local _, long = P:limits()
	local square = sqrt(P.area)
	local squishRate = (long - square) / P.tDecay
	if length > square then
		local dL = min(dt * squishRate, length - square)
		P:stretch(-dL)
	end
end

function Player.computeDeceleration(P)
	P.decel = P.maxSpeed/P.tDecay
end

function Player.computeAcceleration(P)
	local length = P:length()
	local short, long = P:limits()
	local square = sqrt(P.area)
	P.stretchSpeed = (long - square) / P.tAccel
	local k = (long - length) / (long - square)
	local dv = P.maxSpeed - P.speed
	P.accel = k * dv/P.tAccel
end

function Player.update(P, dt, dir)
	P.trail:update(dt, P:center())
	if dir == 0 then
		P.speed = 0
		local short, long = P:limits()
		local square = sqrt(P.area)
		P:stretch(-(long - square)/P.tAccel * dt)
	elseif type(dir) == 'number' and dir ~= P.ignoreDir then
		if dir ~= P.dir then P:turnTo(dir) end
		if dir ~= P.lastDir then
			P.lastDir = dir
			P:computeAcceleration()
		end
		P.speed = min(P.speed + P.accel * dt, P.maxSpeed)
		P:stretch(P.stretchSpeed * dt, P.speed * dt)
		local _, long = P:limits()
		P.ignoreDir = P:length() == long and dir
	else
		P:move(P.speed * dt)
		P:decayShape(dt, dir)
		P.speed = max(0, P.speed - (P.maxSpeed/P.tDecay) * dt)
	end

	if not dir then P.lastDir, P.ignoreDir = false, false end
end

function Player.draw(P)
	local r = P.r
	love.graphics.setColor(0.8, 0.7, 0.3)
	love.graphics.setLineWidth(2)
	love.graphics.rectangle('line', r[3], r[4], r[1]-r[3], r[2]-r[4])
	love.graphics.setLineWidth(4)
	love.graphics.line(P:side(P.dir))

	P.trail:draw()
end

return Player

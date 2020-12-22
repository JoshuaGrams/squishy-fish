local Actor = require 'actor'
local cooldown = require 'cooldown'
local Trail = require 'trail'

local Player = Actor:extend()

local sqrt = math.sqrt
local abs, floor, ceil = math.abs, math.floor, math.ceil
local min, max = math.min, math.max
local function clamp(x, lo, hi) return max(lo, min(x, hi)) end

function Player.set(P, x, y, w, h)
	P.area, P.maxAspect = w*h, w/h
	P.aspect = 1
	w, h = P:size()
	P.r = {x+w/2, y+h/2, x-w/2, y-h/2}  -- clockwise: right, bottom, left, top
	P.speed, P.maxSpeed = 0, 800
	P.tAccel, P.tDecay = 0.15, 0.8
	P.accel = 0
	P.dir = 1
	P.hand, P.deck, P.discards = { size = 3 }, {}, {}
	P.path = {}
	P.health = 8
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

function Player.computeAcceleration(P)
	local x, y = P:center()
	table.insert(P.path, { dir = P.dir, x = x, y = y })
	local length = P:length()
	local short, long = P:limits()
	local square = sqrt(P.area)
	P.stretchSpeed = (long - square) / P.tAccel
	local k = (long - length) / (long - square)
	local dv = P.maxSpeed - P.speed
	P.accel = k * dv/P.tAccel
end

local turns = { F = 0, R = 1, B = 2, L = 3 }

function spellArgs(shape, spell)
	local spellLength = ceil(#spell/2)
	if #shape ~= spellLength then return false end
	local args = {}
	for i,seg in ipairs(shape) do
		local turn, key = turns[spell[2*i-2]], spell[2*i-1]
		if i == 1 then
			args.dir = seg.turn
		elseif seg.turn ~= turn then
			return false
		end
		args[key] = max(args[key] or 0, seg.length)
	end
	return args
end

function Player.discard(P, i)
	table.insert(P.discards, table.remove(P.hand, i))
end

function Player.fillHand(P)
	while #P.deck > 0 and #P.hand < P.hand.size do
		table.insert(P.hand, table.remove(P.deck))
	end
	if #P.hand == 0 then P.shuffleDelay = 2 end
end

local function shuffle(t)
	local i = #t
	while i > 1 do
		i = i - 1
		local j = floor(math.random(i))
		t[i], t[j] = t[j], t[i]
	end
	return t
end

function Player.inHand(P, path)
	for i,spell in ipairs(P.hand) do
		local args = spell:match(path)
		if args then
			P:discard(i)
			P:fillHand()
			args.owner = P
			return spell, args
		end
	end
	return false
end

function Player.maybeCast(P, x, y)
	if #P.path < 1 then return end
	local path = { finish = {x, y} }
	local spellDir = false
	for i,p in ipairs(P.path) do
		local turn
		if not spellDir then
			spellDir, turn = p.dir, p.dir
		else
			turn = (p.dir - spellDir) % 4
		end
		local n = P.path[i+1] or {x=x, y=y}
		table.insert(path, {
			turn = turn,
			length = floor(abs((n.x - p.x) + (n.y - p.y))),
			p = {p.x, p.y}
		})
	end
	P.stopped, P.path = nil, {}
	local spell, args = P:inHand(path)
	if spell then
		spell:cast(args)
		P.trail:flash()
	else
		P.trail:clear()
	end
end

function Player.update(P, dt, dir)
	-- All cards used, wait to shuffle deck and re-deal.
	if cooldown(P, 'shuffleDelay', dt) then
		P.deck, P.discards = P.discards, P.deck
		shuffle(P.deck)
		P:fillHand()
	end
	-- Coasted to a halt, wait to clear spell.
	if cooldown(P, 'stopped', dt) then
		P.path = {}
		P.trail:clear()
	end
	-- Particle trail.
	if dir == 0 or P.speed == 0 then P.trail:update(dt)
	else P.trail:update(dt, P:center()) end
	-- Player proper.
	if dir == 0 then
		P.speed = 0
		local short, long = P:limits()
		local square = sqrt(P.area)
		P:stretch(-0.5*(long - square)/P.tAccel * dt)
		P:maybeCast(P:center())
	elseif type(dir) == 'number' and dir ~= P.ignoreDir then
		P.stopped = nil
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
		if P.speed == 0 and not P.stopped then
			P.stopped = 0.3
		end
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

local Actor = require 'actor'
local Effects = require 'effects'

local min, max = math.min, math.max
local floor = math.floor
local cos, sin = math.cos, math.sin
local TURN = 2*math.pi

local function roundTo(x, unit)
	return floor(0.5 + x/unit) * unit
end

local function scaleTo(u, lo, hi)
	return max(lo, min(lo + (u or 0)*(hi-lo), hi))
end

-- Takes the following from the spell:
-- imgName, invert (flip damage), reverse (flip direction), hit
function Bolt(Spell, args)
		local x, y = unpack(args.origin)
		local w = scaleTo(args.w, 20, 60)
		local speed = scaleTo(args.l, 400, 1500)
		local bolt = Actor(x, y, speed/5, w, I[Spell.imgName or 'energyPink'])
		bolt.damage = roundTo(scaleTo(args.w, 0.5, 5), 0.5)
		if Spell.invert then
			bolt.damage = -bolt.damage
		end
		bolt.bullet = true
		if Spell.reverse then
			bolt.dir = 1 + (1 + args.dir) % 4
		else
			bolt.dir = args.dir
		end
		local th = TURN * (bolt.dir-1)/4
		bolt.vx, bolt.vy = speed*cos(th), speed*sin(th)
		bolt.lifetime = 7.5  -- seconds
		bolt.owner = args.owner
		bolt.hit = Spell.hit or Effects.hurt
		bolt.hitScale = 0.8
		addTo(bolt, bolt.owner.group)
end

return Bolt

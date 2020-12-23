local Actor = require 'actor'
local Effects = require 'effects'

local min, max = math.min, math.max
local ceil = math.ceil
local cos, sin = math.cos, math.sin
local TURN = 2*math.pi

-- Takes the following from the spell:
-- imgName, inverse (flip damage), reverse (flip direction), hit
function Bolt(Spell, args)
		local x, y = unpack(args.origin)
		local w = max(20, min(5 + (args.w or 0)/3, 60))
		local speed = max(200, min(100+3*(args.l or 0), 800))
		local bolt = Actor(x, y, speed/5, w, I[Spell.imgName or 'energyPink'])
		bolt.damage = ceil(0.5 + (w - 19)/10)  -- 1 to 5
		if Spell.inverse then
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

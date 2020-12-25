local Actor = require 'actor'
local cooldown = require 'cooldown'

local Pickup = Actor:extend()

function Pickup.set(S, x, y)
	local coin = math.random() < 0.3
	Actor.set(S, x, y, 60, 60, coin and I.coin or I.fullHeart)
	S.lifetime = 5
	S.bullet = true
	if coin then
		S.spell = spellChoices[math.random(#spellChoices)]
	else
		S.heart = true
	end
end

function Pickup.update(S, dt)
	Actor.update(S, dt)
	if S.lifetime then
		local c = 0.7 + 0.3 * math.cos(8*math.pi * S.lifetime/5)
		S.color[1], S.color[2], S.color[3] = c, c, c
	end
end

function Pickup.hit(S, a)
	if a == player then
		S.group = nil
		if S.heart then
			player.health = math.min(player.health + 1, player.maxHealth)
		end
		if S.spell then
			table.insert(player.hand, S.spell)
		end
	end
end

function Pickup.draw(S)
	Actor.draw(S)
	if S.spell then
		local x, y = S:center()
		local r = S:size()/2
		S.spell:draw(x, y, math.sqrt(2)*r - 2*3)
	end
end

return Pickup

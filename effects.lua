return {

	hurt = function(bolt, actor)
		if actor.health then
			bolt.group = nil
			actor.health = actor.health - bolt.damage
		end
	end,

	swap = function(bolt, actor)
		bolt.group = nil
		local ox, oy = bolt.owner:center()
		bolt.owner:setPos(actor:center())
		actor:setPos(ox, oy)
	end,

	push = function(bolt, actor)
		bolt.group = nil
		local vx, vy = bolt.vx, bolt.vy
		local sc = 100*bolt.damage / math.sqrt(vx*vx + vy*vy)
		actor.vx = (actor.vx or 0) + sc*vx
		actor.vy = (actor.vy or 0) + sc*vy
	end,

	convert = function(bolt, actor)
		bolt.group = nil
		actor.group = bolt.owner.group
	end

}

return {

	hurt = function(bolt, actor)
		bolt.group = nil
		if actor.health then
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
		local sc = 50*bolt.damage / math.sqrt(vx*vx + vy*vy)
		actor.vx = actor.vx + sc*vx
		actor.vy = actor.vy + sc*vy
	end,

	convert = function(bolt, actor)
		bolt.group = nil
		actor.group = bolt.owner.group
	end

}

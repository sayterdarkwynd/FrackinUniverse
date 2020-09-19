function init()
	script.setUpdateDelta(3)
	self.valBonus = config.getParameter("valBonus")
	self.baseVal = config.getParameter("baseValue",1)
end

function update(dt)
	if (world.entityType(entity.id())~="player") or world.getProperty("invinciblePlayers") or status.statPositive("invulnerable") then
		return {}
	end
	
	if not status.statusProperty("fu_afk_30s") then
		if (math.abs(mcontroller.xVelocity()) < 5) and (math.abs(mcontroller.yVelocity()) < 5) then
			self.randVal = math.floor(((math.random(1,4)+self.baseVal)*(1.0 - status.stat("mentalProtection")))*self.valBonus)
			if (self.randVal > 0) then
				world.spawnItem("fumadnessresource",entity.position(),self.randVal)
			end
		end
	end
end

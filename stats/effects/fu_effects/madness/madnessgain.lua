function init()
	script.setUpdateDelta(3)
	self.valBonus = config.getParameter("valBonus")
	self.baseVal = config.getParameter("baseValue",1)

	self.penaltyAmount=1.0
	self.penaltyRate=0.01 -- -1% shadow resistance per second
end

function update(dt)
	if (world.entityType(entity.id())~="player") or world.getProperty("invinciblePlayers") or status.statPositive("invulnerable") then
		return {}
	end
	local afkLvl=afkLevel()

	self.penaltyTimer = (self.penaltyTimer or 0.0) + dt
	if self.penaltyTimer >= 1 then
		self.penaltyAmount=((afkLvl>0) and math.max(0,self.penaltyAmount-(self.penaltyRate*self.penaltyTimer*afkLvl))) or 0.0
		self.penaltyTimer=0.0
	end

	if (math.abs(mcontroller.xVelocity()) < 5) and (math.abs(mcontroller.yVelocity()) < 5) then
		self.randVal = math.floor((((math.random(1,4-afkLvl)+self.baseVal)*(1.0 - status.stat("mentalProtection")))*self.valBonus) * self.penaltyAmount)
		if (self.randVal > 0) then
			world.spawnItem("fumadnessresource",entity.position(),self.randVal)
		end
	end
end

function afkLevel()
	return ((status.statusProperty("fu_afk_720s") and 4) or (status.statusProperty("fu_afk_360s") and 3) or (status.statusProperty("fu_afk_240s") and 2) or (status.statusProperty("fu_afk_120s") and 1) or 0)
end
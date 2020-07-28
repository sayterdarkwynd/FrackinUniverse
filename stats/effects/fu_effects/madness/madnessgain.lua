function init()
	script.setUpdateDelta(3)
	self.valBonus = config.getParameter("valBonus")
	self.baseVal = config.getParameter("baseValue") or 1
	self.myspeed = 0
	self.afk = 0
end

function update(dt)
	if world.getProperty("invinciblePlayers") or status.statPositive("invulnerable") then
	--don't work if players are invuln
		return {}
	end
	self.penalty = status.stat("mentalProtection") or 0
	self.baseVal = self.baseVal or math.random(1,4) - self.penalty
	self.randVal = self.baseVal * self.valBonus
	self.myspeed = mcontroller.xVelocity() --check speed, dont drop madness if we are afking
	if world.entityType(entity.id())=="player" then
		if self.myspeed < 1 then
			if self.afk > 300 then -- do not go higher than this value
				self.afk = 300
			end
			self.afk = self.afk + 1
			world.spawnItem("fumadnessresource",entity.position(),self.randVal)
		else
			self.afk = self.afk -2	--movement decrements the penalty
			if self.afk < 0 then
				self.afk = 0
			end
		end
	else
		effect.expire()
	end
end

function uninit()

end

function checkSpeed()
	self.myspeed = mcontroller.xVelocity() --check speed, dont drop madness if we are afking
	if self.myspeed < 2 then
		if self.afk > 200 then -- do not go higher than this value
			self.afk = 200
		end
		self.afk = self.afk + 1
		sb.logInfo(self.afk)
	else
		self.afk = self.afk -2	--movement decrements the penalty
	end
end

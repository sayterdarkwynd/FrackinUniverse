local teamFlips={enemy={type="friendly",team=1},friendly={type="enemy",team=2}}

function init()
	if status.statPositive("specialStatusImmunity") or status.statPositive("insanityImmunity") then effect.expire() end
	self.entType=world.entityType(entity.id())
	if not self.entType then return end
	if self.entType=="player" then
		self.originalTeam="player"
	else
		self.originalTeam=status.statusProperty("originalTeam")
	end
	if not self.originalTeam then
		self.originalTeam=world.entityDamageTeam(entity.id())
		status.setStatusProperty("originalTeam",self.originalTeam)
	end
	if self.originalTeam~="player" then
		status.addEphemeralEffect("teamshiftvfx",dt)
		self.swapTeam=teamFlips[self.originalTeam.type]
		if self.swapTeam then
			world.callScriptedEntity(entity.id(),self.entType..".setDamageTeam",self.swapTeam)
		end
	end
	self.didInit=true
end

function update(dt)
	if not self.didInit then
		init()
	end
	status.addEphemeralEffect("teamshiftvfx",dt)
end

function uninit()
	if self.originalTeam and (self.originalTeam~="player") then
		if world.entityExists(entity.id()) then world.callScriptedEntity(entity.id(),self.entType..".setDamageTeam",self.originalTeam) end
	end
end

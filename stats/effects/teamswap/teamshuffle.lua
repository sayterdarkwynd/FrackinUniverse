local teamFlips={{type="friendly",team=1},{type="enemy",team=2},{type="indiscriminate",team=3}}

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
		randostick()
	end
	self.didInit=true
end

function update(dt)
	if not self.didInit then
		init()
		if (not self.didInit) then return end
	end
	if self.lockTimer then
		self.lockTimer=self.lockTimer-dt
		if self.lockTimer<=0 then
			self.lockTimer=nil
		else
			return
		end
	end
	randostick()
end

function uninit()
	if self.originalTeam and (self.originalTeam~="player") then
		if world.entityExists(entity.id()) then world.callScriptedEntity(entity.id(),self.entType..".setDamageTeam",self.originalTeam) end
	end
end

function randostick()
	if not (self.originalTeam=="player") then
		local wiggleRoom=math.random(1,3)
		if wiggleRoom==1 then
			effect.modifyDuration(1)
		elseif wiggleRoom==2 then
			self.lockTimer=3.0
		else
			world.callScriptedEntity(entity.id(),self.entType..".setDamageTeam",teamFlips[math.random(#teamFlips)])
		end
	end
end
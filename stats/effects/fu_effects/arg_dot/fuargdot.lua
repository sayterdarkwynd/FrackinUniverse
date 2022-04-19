require "/scripts/effectUtil.lua"

function init()
	--10s internal timer, refreshed to 10s on reapply
	self.baseDuration=config.getParameter("baseDuration",10)
	self.tickTime=config.getParameter("tickInterval",1.0)
	local dur=effect.duration()
	self.duration=self.baseDuration
	self.damage=dur/self.baseDuration
	effect.modifyDuration(self.baseDuration-dur)
	self.element=config.getParameter("element","default")
	if type(self.element)=="string" then self.element={self.element} end
	--sb.logInfo("i %s",{self.damage,self.baseDuration,#self.element,self.damage/#self.element})
	--{1: 3, 2: 10, 3: 2, 4: 1.5}
end

function update(dt)
	--internal timer
	local dur=effect.duration()
	self.duration=self.duration-dt
	if self.duration<=0 then
		effect.expire()
		return
	end

	--check duration, if it's not within an expected range we reset it back to max duration after power recalc.
	--sb.logInfo("e %s",{self.damage,self.baseDuration,#self.element,self.damage/#self.element,dur})
	if (self.duration~=dur) and (math.abs(self.duration-dur)>(2*dt)) then
		self.damage=dur/self.baseDuration
		effect.modifyDuration(self.baseDuration-dur)
		self.duration=self.baseDuration
		--sb.logInfo("!e %s",{self.damage,self.baseDuration,#self.element,self.damage/#self.element})
	end

	self.tickTimer = math.max(0,(self.tickTimer or self.tickTime) - dt)
	if self.tickTimer <= 0 then
		local splitter=#self.element
		for _,element in pairs(self.element) do
			status.applySelfDamageRequest({damageType = "Damage",damage = self.damage/splitter,damageSourceKind = element,sourceEntityId = self.source})
		end
		self.tickTimer = self.tickTime
	end
end


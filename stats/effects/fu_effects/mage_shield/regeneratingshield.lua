require "/scripts/status.lua"

function init()
	if not trackerHandler then trackerHandler=effect.addStatModifierGroup({}) end
	self.damageListener = damageListener("damageTaken", checkDamage)
	self.shieldCap=config.getParameter("shieldCap",1.0)
	self.resource=config.getParameter("resource","health")
	self.shieldBlockTime=config.getParameter("shieldBlockTime",3)
	self.shieldRegenRate=config.getParameter("shieldRegenRate",0.1)
	self.shieldBlockTimer=0.0
end

function update(dt) 
	self.damageListener:update()
	local capCalc=self.shieldCap*status.resourceMax(self.resource)
	local shieldPercent=status.resource("damageAbsorption") / capCalc
	
	if self.shieldBlockTimer and self.shieldBlockTimer>0 then
		self.shieldBlockTimer = (self.shieldBlockTimer-dt)
	elseif shieldPercent < 1.0 then
		status.modifyResource("damageAbsorption",math.min(dt*self.shieldRegenRate*capCalc,capCalc-status.resource("damageAbsorption")))
		shieldPercent=status.resource("damageAbsorption") / capCalc
	elseif shieldPercent > 1.0 then
		status.modifyResource("damageAbsorption",-capCalc*dt*self.shieldRegenRate)
		shieldPercent=status.resource("damageAbsorption") / capCalc
	end
	
		
	--world.sendEntityMessage(entity.id(),"setBar","mageShieldBar",shieldPercent,{250,0,250,200})--we let the using armor set the indicator
	effect.setStatModifierGroup(trackerHandler,{{stat="regeneratingshieldpercent",amount=shieldPercent}})
end

function uninit()
	effect.modifyResource("damageAbsorption", -status.resource("damageAbsorption"))
	if trackerHandler then effect.removeStatModifierGroup(trackerHandler) end
end

function checkDamage(notifications)
	self.shieldBlockTimer=self.shieldBlockTime
end
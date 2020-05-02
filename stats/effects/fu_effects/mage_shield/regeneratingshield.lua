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
	
	if self.shieldBlockTimer and self.shieldBlockTimer>0 then
		self.shieldBlockTimer = (self.shieldBlockTimer-dt)
	elseif status.resource("damageAbsorption") < capCalc() then
		status.modifyResource("damageAbsorption",math.min(dt*self.shieldRegenRate*capCalc(),capCalc()-status.resource("damageAbsorption")))
	elseif status.resource("damageAbsorption") > capCalc() then
		status.modifyResource("damageAbsorption",capCalc()*dt*self.shieldRegenRate)
	end
	updateShield()
end

function uninit()
	if trackerHandler then status.removeStatModifierGroup(trackerHandler) end
	effect.modifyResource("damageAbsorption", -status.resource("damageAbsorption"))
end


function updateShield()
	local shieldPercent=status.resource("damageAbsorption") / capCalc()
	world.sendEntityMessage(entity.id(),"setBar","mageShieldBar",shieldPercent,{250,0,250,200})
	effect.setStatModifierGroup(trackerHandler,{{stat="regeneratingshieldpercent",amount=shieldPercent}})
end

function checkDamage(notifications)
	self.shieldBlockTimer=self.shieldBlockTime
end

function capCalc()
	return self.shieldCap*status.resourceMax(self.resource)
end
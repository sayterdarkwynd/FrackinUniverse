require "/scripts/status.lua"

function init()
	self.damageListener = damageListener("damageTaken", checkDamage)
	self.shieldCap=config.getParameter("shieldCap",1.0)
	self.resource=config.getParameter("resource","health")
	self.shieldBlockTime=config.getParameter("shieldBlockTime",3)
	self.shieldRegenRate=config.getParameter("shieldRegenRate",0.1)
	self.shieldBlockTimer=0.0
end

function update(dt) 
	if self.shieldBlockTimer and self.shieldBlockTimer>0 then
		self.shieldBlockTimer = self.shieldBlockTimer-dt
	else status.resource("damageAbsorption") < capCalc() then
		status.modifyResource("damageAbsorption",math.min(dt*self.shieldRegenRate*capCalc(),capCalc()-status.resource("damageAbsorption")))
	else status.resource("damageAbsorption") > (status.resourceMax("health")*shieldCap) then
		status.modifyResource("damageAbsorption",capCalc()*dt*self.shieldRegenRate)
	end
	updateShield()
end

function uninit()
	status.modifyResource("damageAbsorption", -status.resource("damageAbsorption"))
end


function updateShield()
	world.sendEntityMessage(entity.id(),"setBar","mageShieldBar",status.resource("damageAbsorption") / capCalc(),{250,0,250,200}) 
end

function checkDamage(notifications)
	self.shieldBlockTimer=self.shieldBlockTime
end

function capCalc()
	self.shieldCap*status.resourceMax(self.resource)
end
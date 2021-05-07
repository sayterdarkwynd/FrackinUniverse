require "/scripts/status.lua"

function init()
	if not status.isResource("damageAbsorption") then return end
	if not trackerHandler then trackerHandler=effect.addStatModifierGroup({}) end
	self.damageListener = damageListener("damageTaken", checkDamage)
	self.shieldCap=config.getParameter("shieldCap",1.0)
	self.resource=config.getParameter("resource","health")

	self.baseShieldRegenRate=config.getParameter("shieldRegenRate",0.1)
	self.useSpecialRegen=config.getParameter("useSpecialRegen")
	if self.useSpecialRegen then
		self.specialRegenStat=config.getParameter("specialRegenStat","energyRegenPercentageRate")
	end

	self.baseShieldBlockTime=config.getParameter("shieldBlockTime",3)
	self.useSpecialBlock=config.getParameter("useSpecialBlock")
	if self.useSpecialBlock then
		self.specialBlockStat=config.getParameter("specialBlockStat","energyRegenBlockTime")
	end
	handleStatCalc()

	self.shieldBlockTimer=self.shieldBlockTime
end

function handleStatCalc()
	self.shieldRegenRate=self.baseShieldRegenRate
	if self.useSpecialRegen then
		self.shieldRegenRate=self.shieldRegenRate*status.stat(self.specialRegenStat)
	end
	self.shieldBlockTime=self.baseShieldBlockTime
	if self.useSpecialBlock then
		self.shieldBlockTime=math.max(0.1,self.shieldBlockTime*status.stat(self.specialBlockStat))
	end
	self.capCalc=self.shieldCap*status.resourceMax(self.resource)
end

function update(dt)
	if not status.isResource("damageAbsorption") then return end
	self.damageListener:update()
	handleStatCalc()
	local shieldPercent=status.resource("damageAbsorption") / self.capCalc

	if self.shieldBlockTimer and self.shieldBlockTimer>0 then
		self.shieldBlockTimer = math.max(0,self.shieldBlockTimer-dt)
	elseif shieldPercent < 1.0 then
		status.modifyResource("damageAbsorption",math.min(dt*self.shieldRegenRate*self.capCalc,self.capCalc-status.resource("damageAbsorption")))
		shieldPercent=status.resource("damageAbsorption") / self.capCalc
	elseif shieldPercent > 1.0 then
		status.modifyResource("damageAbsorption",-self.capCalc*dt*self.shieldRegenRate)
		shieldPercent=status.resource("damageAbsorption") / self.capCalc
	end

	effect.setStatModifierGroup(trackerHandler,{{stat="regeneratingshieldpercent",amount=shieldPercent}})
end

function uninit()
	if not status.isResource("damageAbsorption") then return end
	status.modifyResource("damageAbsorption", - status.resource("damageAbsorption"))
	if trackerHandler then effect.removeStatModifierGroup(trackerHandler) end
end

function checkDamage(notifications)
	self.shieldBlockTimer=self.shieldBlockTime
end
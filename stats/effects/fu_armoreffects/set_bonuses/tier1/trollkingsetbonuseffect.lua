require "/scripts/status.lua"
require "/stats/effects/fu_armoreffects/setbonuses_common.lua"
setName="fu_trollkingset"

weaponBonus2={
	{stat="powerMultiplier",effectiveMultiplier=2}
}

armorBonus={
	{stat="fuCharisma",baseMultiplier=0},
	{stat="erchiusImmunity",amount=1},
	{stat="insanityImmunity",effectiveMultiplier=0},
	{stat="mentalProtection",effectiveMultiplier=0}
}

function init()
	setSEBonusInit(setName)
	effectHandlerList.weaponBonusHandle2=effect.addStatModifierGroup({})
	checkWeapons()
	effectHandlerList.armorBonusHandle=effect.addStatModifierGroup(armorBonus)
	self.hungerEnabled=status.isResource("food")
	if self.hungerEnabled then
		self.regenTimer=0.0
		self.listener = damageListener("damageTaken", function() self.regenTimer=10.0 end)
	end
end

function update(dt)
	if not checkSetWorn(self.setBonusCheck) then
		status.removeEphemeralEffect("trollkingshell")
		removePetBuffs()
		setRegen(0)
		effect.expire()
	else
		if self.hungerEnabled then
			self.listener:update()
			self.regenTimer=math.max(0,(self.regenTimer or 0.0) - dt)
			self.accelerateRegen=self.regenTimer <= 0
			if self.accelerateRegen then
				local hPcnt=status.resourcePercentage("health")
				if hPcnt < 1.0 then
					status.modifyResourcePercentage("food",math.min((1.0-hPcnt),0.1)*-1*dt)
					status.removeEphemeralEffect("wellfed")
				end
			end
		end
		setRegen((self.accelerateRegen and 0.1) or 0.01)
		setPetBuffs({"trollkingshell"})
		status.addEphemeralEffect("trollkingshell")
		checkWeapons()
	end
end

function checkWeapons()
	local weaponSword=weaponCheck({"failtrollflail"})

	if weaponSword["both"] then
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle2,weaponBonus2)
		status.addEphemeralEffect("ghostburst_armorset",1)
	else
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle2,{})
	end
end

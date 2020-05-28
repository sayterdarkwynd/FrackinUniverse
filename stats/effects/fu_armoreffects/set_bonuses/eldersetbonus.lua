require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

setName="fu_elderset"
setEffects={"darkregen"}


weaponBonus={
	{stat = "powerMultiplier", effectiveMultiplier = 1.25}
}

armorBonus={
	{stat = "shadowImmunity", amount = 1},
	{stat = "liquidnitrogenImmunity", amount = 1},
	{stat = "insanityImmunity", amount = 1},
	{stat = "pusImmunity", amount = 1},
	{stat = "sulphuricImmunity", amount = 1}
}

petBuffList={"fudarkcommander30"}

function init()
	setSEBonusInit(setName,setEffects)
	effectHandlerList.armorBonusHandle=effect.addStatModifierGroup({})
	effectHandlerList.weaponBonusHandle=effect.addStatModifierGroup({})
	
	handleBonuses(0,checkSetWorn(self.setBonusCheck))
end

function update(dt)
	handleBonuses(dt,checkSetWorn(self.setBonusCheck))
end

function handleBonuses(dt,on)
	if not self.petBuffTimer or self.petBuffTimer >= 1 then
		if not on then
			removePetBuffs()
		else
			setPetBuffs(petBuffList)
		end
		self.petBuffTimer = 0
	else
		self.petBuffTimer = self.petBuffTimer + dt
	end
	if on then
		effect.setStatModifierGroup(effectHandlerList.armorBonusHandle,armorBonus)
		applySetEffects()
	else
		effect.setStatModifierGroup(effectHandlerList.armorBonusHandle,{})
	end
	checkWeapons(not on)
end

function checkWeapons(autofail)
	if autofail then effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,{}) return end
	
	local weapons=weaponCheck({"elder"})
	if weapons["either"] then
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,weaponBonus)
	else
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,{})
	end
end
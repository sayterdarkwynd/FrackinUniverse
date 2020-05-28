require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

setName="fu_corruptset"
setEffects={"scouteyecultistblast"}

biomeList={"lightless","penumbra","aethersea","moon_shadow","shadow","midnight"}
armorBonus2={
	{stat = "maxHealth", effectiveMultiplier = 1.25},
	{stat = "powerMultiplier", effectiveMultiplier = 1.15}
}

armorBonus={
	{stat = "sulphuricImmunity", amount = 1},
	{stat = "poisonStatusImmunity", amount = 1}
}

function init()
	setSEBonusInit(setName,setEffects)
	effectHandlerList.armorBonusHandle=effect.addStatModifierGroup({})
	effectHandlerList.armorBonus2Handle=effect.addStatModifierGroup({})
	
	handleBonuses(0,checkSetWorn(self.setBonusCheck))
end

function update(dt)
	handleBonuses(dt,checkSetWorn(self.setBonusCheck))
end

function handleBonuses(dt,on)
	if on then
		effect.setStatModifierGroup(effectHandlerList.armorBonusHandle,armorBonus)
		applySetEffects()
	else
		effect.setStatModifierGroup(effectHandlerList.armorBonusHandle,{})
	end
	checkArmor(not on)
end

function checkArmor(autofail)
	if autofail then effect.setStatModifierGroup(effectHandlerList.armorBonus2Handle,{}) return end
	if checkBiome(biomeList) then
		effect.setStatModifierGroup(effectHandlerList.armorBonus2Handle,armorBonus2)
	else
		effect.setStatModifierGroup(effectHandlerList.armorBonus2Handle,{})
	end
end


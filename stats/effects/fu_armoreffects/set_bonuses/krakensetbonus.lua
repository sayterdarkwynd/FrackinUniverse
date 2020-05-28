require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

setName="fu_krakenset"
setEffects={"swimboost2"}

biomeList={"ocean", "sulphuricocean", "aethersea", "nitrogensea", "strangesea", "tidewater"}
armorBonus2={
	{stat = "critChance", amount = 4},
	{stat = "powerMultiplier", effectiveMultiplier = 1.15}
}

armorBonus={
	{stat = "sulphuricImmunity", amount = 1},
	{stat = "gasImmunity", amount = 1},
	{stat = "poisonStatusImmunity", amount = 1},
	{stat = "biooozeImmunity", amount = 1},
	{stat = "breathProtection", amount = 1}
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
	checkBiome(not on)
end

function checkBiome(autofail)
	if autofail then effect.setStatModifierGroup(effectHandlerList.armorBonus2Handle,{}) return end

	if checkBiome(biomeList) then
		effect.setStatModifierGroup(effectHandlerList.armorBonus2Handle,armorBonus2)
		mcontroller.controlModifiers({speedModifier = 1.05})
	else
		effect.setStatModifierGroup(effectHandlerList.armorBonus2Handle,{})
	end
end
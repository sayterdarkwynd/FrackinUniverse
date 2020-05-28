require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

setName="fu_morphiteset2"

armorBonus={
  {stat = "biomeheatImmunity", amount = 1},
  {stat = "biomecoldImmunity", amount = 1},
  {stat = "biomeradiationImmunity", amount = 1},
  {stat = "ffextremeheatImmunity", amount = 1},
  {stat = "ffextremecoldImmunity", amount = 1},
  {stat = "ffextremeradiationImmunity", amount = 1},
  {stat = "sulphuricImmunity", amount = 1}
}

function init()
	setSEBonusInit(setName,setEffects)
	effectHandlerList.armorBonusHandle=effect.addStatModifierGroup({})
	
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
end

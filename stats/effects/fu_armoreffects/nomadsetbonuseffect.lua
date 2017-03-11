require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

weaponBonus={
	{stat = "powerMultiplier", amount = 0.10}
}

armorBonus2={
{stat = "blacktarImmunity", amount = 1},
{stat = "quicksandImmunity", amount = 1},
{stat = "radiationburnImmunity", amount = 1},
{stat = "sandstormImmunity", amount = 1},
{stat = "shieldStaminaRegen", baseMultiplier = 1.20},
{stat = "maxHealth", baseMultiplier = 1.15},
{stat = "maxEnergy", baseMultiplier = 1.10}
}

armorBonus={
{stat = "blacktarImmunity", amount = 1},
{stat = "quicksandImmunity", amount = 1},
{stat = "sandstormImmunity", amount = 1},
{stat = "radiationburnImmunity", amount = 1},
{stat = "shieldStaminaRegen", baseMultiplier = 1.20}
}

setName="fu_nomadset"

function init()
	setSEBonusInit(setName)
	weaponBonusHandle=effect.addStatModifierGroup({})

	checkWeapons()

	armorBonusHandle=effect.addStatModifierGroup(armorBonus)
if (world.type() == "desert") or (world.type() == "desertwastes") or (world.type() == "desertwastesdark") then--optional condition to have different armor bonuses
	effect.setStatModifierGroup(
	armorBonusHandle,armorBonus2)
end
	
end

function update(dt)
if not checkSetWorn(self.setBonusCheck) then
	effect.expire()
else
	
	checkWeapons()
end
if (world.type() == "desert") or (world.type() == "desertwastes") or (world.type() == "desertwastesdark") then--optional condition to have different armor bonuses
	effect.setStatModifierGroup(
	armorBonusHandle,armorBonus2)
else
	effect.setStatModifierGroup(
	armorBonusHandle,armorBonus1)
end
end

function checkWeapons()
	local weapons=weaponCheck({"dagger","knife"})
        if weapons["either"] then--set both for dual wield required, or leave as is for "if any hand, do."
	  effect.setStatModifierGroup(weaponBonusHandle,weaponBonus)
        else
	  effect.setStatModifierGroup(weaponBonusHandle,{})
        end
end
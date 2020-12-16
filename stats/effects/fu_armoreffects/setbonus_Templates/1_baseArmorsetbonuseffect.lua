setName="fu_setname" --this should match what you put in the template shell.

weaponBonus={ -- if it is to have stats from weapons wielded, enter them here
	{stat = "critChance", amount = 25}
}

armorBonus={	-- whatever bonuses the armor provides go here
{stat = "iceResistance", amount = 0.15},
{stat = "coldimmunity", amount = 1}
}
armorBonus2={	-- whatever bonuses the armor provides go here
{stat = "iceResistance", amount = 0.2},
{stat = "coldimmunity", amount = 1}
}

require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

function init()
	setSEBonusInit(setName)

	armorBonusHandle=effect.addStatModifierGroup(armorBonus)
if false then--optional condition to have different armor bonuses
	effect.setStatModifierGroup(
	armorBonusHandle,armorBonus2)
end
	weaponBonusHandle=effect.addStatModifierGroup({})
myFunction()
end

function update(dt)
if not checkSetWorn(self.setBonusCheck) then
	effect.expire() --Khe: Treat this the same as return: it goes last in this code piece
else
	if false then--optional condition to have different armor bonuses
		effect.setStatModifierGroup(
	armorBonusHandle,armorBonus2)
	else
		effect.setStatModifierGroup(
	armorBonusHandle,armorBonus)
	end
	myFunction()	-- we can run custom functions here to make all sorts of neat shit possible
end
end

function myFunction()
	local weapons=weaponCheck({"axe","hammer"})
if weapons["either"] then	-- weaponCheck is run in setbonuses core file)
	effect.setStatModifierGroup(weaponBonusHandle,weaponBonus)
else
	effect.setStatModifierGroup(weaponBonusHandle,{})
end
end
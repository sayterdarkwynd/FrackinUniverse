require "/stats/effects/fu_armoreffects/setbonuses_common.lua"
weaponEffect={{stat = "critChance", amount = 25}}

function init()
	setSEBonusInit("fu_bearset")
	effect.addStatModifierGroup({{stat = "iceResistance", amount = 0.15},{stat = "coldimmunity", amount = 1}})
	handler=effect.addStatModifierGroup({})
	bearPawCheck()
end

function update()
	if not checkSetWorn(self.setBonusCheck) then
		effect.expire()
	else
		bearPawCheck()
	end
end

function bearPawCheck()
	if weaponCheck("both",{"axe","hammer"},false) then
		effect.setStatModifierGroup(handler,weaponEffect)
	else
		effect.setStatModifierGroup(handler,{})
	end
end
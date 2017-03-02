setName="fu_xenoset"
setStatEffects={"xenosetbonuseffect", "novax10", "runboost",}

require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

function init()
	setSEBonusInit(setName,setStatEffects)
end

function update()
	if checkSetWorn(self.setBonusCheck) then
		applySetEffects()
	end
end

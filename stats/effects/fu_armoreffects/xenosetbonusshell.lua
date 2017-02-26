require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

function init()
	setSEBonusInit("fu_xenoset", {"fu_xenoseteffect"})
end

function update()
	if checkSetWorn(self.setBonusCheck) then
		applySetEffects()
	end
end

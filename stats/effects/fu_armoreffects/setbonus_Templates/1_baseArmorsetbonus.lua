setName="fu_setname" -- enter the set bonus name as per the armor file
setStatEffects={"statuseffectname"} -- enter your statuseffect name

require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

function init()
	setSEBonusInit(setName,setStatEffects) -- dont need to change the names on the left. those are fine
end

function update()
	if checkSetWorn(self.setBonusCheck) then
		applySetEffects()
	end
end
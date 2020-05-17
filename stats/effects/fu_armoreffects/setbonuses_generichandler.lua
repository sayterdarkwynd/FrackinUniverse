--going to phase out the 'handler' since tooltips are going away.

require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

function init()
	setName=config.getParameter("setName","generic")
	setStatEffects=config.getParameter("setStatEffects",{})
	setSEBonusInit(setName,setStatEffects)
end

function update()
	if self.setBonusCheck and checkSetWorn(self.setBonusCheck) then
		applySetEffects()
	elseif not self.setBonusCheck then
		setSEBonusInit(setName,setStatEffects)
	end
end
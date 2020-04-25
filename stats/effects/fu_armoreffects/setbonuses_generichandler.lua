--going to phase out the 'handler' since tooltips are going away.

require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

function init()
	setName=config.getParameter("setName","generic")
	setStatEffects=config.getParameter("setStatEffects",{})
	setSEBonusInit(setName,setStatEffects)
end

function update()
	if checkSetWorn(self.setBonusCheck) then
		applySetEffects()
	end
end


function init()
	effect.expire()
end
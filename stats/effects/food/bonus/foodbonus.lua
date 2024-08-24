require "/stats/effects/fu_statusUtil.lua"

function init()
	local foodStats=config.getParameter("stats")
	if foodStats then
		effect.addStatModifierGroup(foodStats)
	end
	self.foodControlMods=config.getParameter("controlModifiers")
end

function update(dt)
	if self.foodControlMods then
		applyFilteredModifiers(self.foodControlMods)
	end
end


function uninit()
	filterModifiers({},true)
end

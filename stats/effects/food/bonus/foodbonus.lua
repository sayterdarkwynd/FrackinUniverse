function init()
	local foodStats=config.getParameter("stats")
	if foodStats then
		effect.addStatModifierGroup(foodStats)
	end
	self.foodControlMods=config.getParameter("controlModifiers")
end

function update(dt)
	if self.foodControlMods then
		mcontroller.controlModifiers(filterModifiers(copy(self.foodControlMods)))
	end
end

function filterModifiers(stuff)
	if (status.statPositive("spikeSphereActive") and 1.0) and stuff["speedModifier"] then stuff["speedModifier"]=1.0 end
	return stuff
end

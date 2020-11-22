require "/scripts/unifiedGravMod.lua"
local handle=nil

function init()
	unifiedGravMod.init()
	effect.addStatModifierGroup({ {stat = "gravrainImmunity", amount = 1} })
	self.powerModifier = config.getParameter("powerModifier", 0)
	effect.addStatModifierGroup({{stat = "powerMultiplier", baseMultiplier = self.powerModifier}})
	self.gravParam=config.getParameter("gravityMod",0)
end
 
function update(dt)
	self.newGravityMultiplier = status.resource("customGravity")*(self.gravParam or 0)
	if handle==nil then
		handle=effect.addStatModifierGroup({ {stat = "gravityMod", amount=self.newGravityMultiplier} })
	else
		effect.setStatModifierGroup(handle,{ {stat = "gravityMod", amount=self.newGravityMultiplier} })
	end
	unifiedGravMod.refreshGrav(dt)
end
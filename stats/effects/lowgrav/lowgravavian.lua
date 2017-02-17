require "/scripts/unifiedGravMod.lua"
local handle=nil

function init()
    effect.addStatModifierGroup({ {stat = "gravrainImmunity", amount = 1} })
    --local bounds = mcontroller.boundBox()
    self.powerModifier = config.getParameter("powerModifier", 0)
    effect.addStatModifierGroup({{stat = "powerMultiplier", baseMultiplier = self.powerModifier}})
end
 
function update()
	self.newGravityMultiplier = status.resource("customGravity")*config.getParameter("gravityBaseMod",0)
	if handle==nil then
		handle=effect.addStatModifierGroup({ {stat = "gravityBaseMod", amount=self.newGravityMultiplier} })
	else
		effect.replaceStatModifierGroup(handle,{ {stat = "gravityBaseMod", amount=self.newGravityMultiplier} })
	end
     unifiedGravMod.refreshGravity()
     --mcontroller.controlParameters({
       --gravityMultiplier = config.getParameter("gravityModifier") * self.newGravityMultiplier
     --})
end
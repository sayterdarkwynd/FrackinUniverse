require "/scripts/unifiedGravMod.lua"
local handle=nil

function init()
	unifiedGravMod.init()
    effect.addStatModifierGroup({ {stat = "gravrainImmunity", amount = 1} })
    --local bounds = mcontroller.boundBox()
    self.powerModifier = config.getParameter("powerModifier", 0)
    effect.addStatModifierGroup({{stat = "powerMultiplier", baseMultiplier = self.powerModifier}})
end
 
function update(dt)
	self.newGravityMultiplier = status.resource("customGravity")*config.getParameter("gravityMod",0)
	if handle==nil then
		handle=effect.addStatModifierGroup({ {stat = "gravityMod", amount=self.newGravityMultiplier} })
	else
		effect.setStatModifierGroup(handle,{ {stat = "gravityMod", amount=self.newGravityMultiplier} })
	end
   --unifiedGravMod.update(dt)
   unifiedGravMod.refreshGrav(dt)
     --mcontroller.controlParameters({
       --gravityMultiplier = config.getParameter("gravityModifier") * self.newGravityMultiplier
     --})
end

function init()
    effect.addStatModifierGroup({ {stat = "gravrainImmunity", amount = 1} })
    local bounds = mcontroller.boundBox()
    self.powerModifier = config.getParameter("powerModifier", 0)
    effect.addStatModifierGroup({{stat = "powerMultiplier", baseMultiplier = self.powerModifier}})
end
 
function update()

     self.newGravityMultiplier = status.resource("customGravity")
     mcontroller.controlParameters({
       gravityMultiplier = config.getParameter("gravityModifier") * self.newGravityMultiplier
     })
end
 
function unit()

end

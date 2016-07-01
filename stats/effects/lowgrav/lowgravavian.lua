
function init()
    effect.addStatModifierGroup({ {stat = "gravrainImmunity", amount = 1} })
    local bounds = mcontroller.boundBox()
    self.powerModifier = effect.configParameter("powerModifier", 0)
    effect.addStatModifierGroup({{stat = "powerMultiplier", baseMultiplier = self.powerModifier}})
end
 
function update()

     self.newGravityMultiplier = status.resource("customGravity")
     mcontroller.controlParameters({
       gravityMultiplier = effect.configParameter("gravityModifier") * self.newGravityMultiplier
     })
end
 
function unit()

end

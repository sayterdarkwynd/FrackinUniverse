require "/scripts/vec2.lua"

function init()
  self.teleported = false
  status.addEphemeralEffect("nofallinvis")
end

function update(dt)
  if effect.sourceEntity() and world.entityExists(effect.sourceEntity()) and not self.teleported and not status.statPositive("activeMovementAbilities") then
    local targetPosition = vec2.add(world.entityMouthPosition(effect.sourceEntity()), {0,-1.5})
    world.sendEntityMessage(effect.sourceEntity(), "openDoor")
    mcontroller.setPosition(targetPosition)
    self.teleported = true
  end

  if self.teleported or status.statPositive("activeMovementAbilities") then
    effect.expire()
  end
end

function init()
  self.teleported = false
end
function update(dt)
  if effect.sourceEntity() and world.entityExists(effect.sourceEntity()) and not self.teleported and not status.statPositive("activeMovementAbilities") then
	local targetPosition = world.entityMouthPosition(effect.sourceEntity())
	world.sendEntityMessage(effect.sourceEntity(), "openDoor")
	mcontroller.setPosition(targetPosition)
	self.teleported = true
  end
  if self.teleported or status.statPositive("activeMovementAbilities") then
	effect.expire()
  end
end
function uninit()
end

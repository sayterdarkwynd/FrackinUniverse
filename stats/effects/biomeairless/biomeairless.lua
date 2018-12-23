function update(dt)
	if not world.breathable(world.entityMouthPosition(entity.id())) then
    if (self.warningUsed ~= true) then
      world.sendEntityMessage(entity.id(), "queueRadioMessage", "biomeairless", 1.0)
      self.warningUsed = true
    end
	end
end

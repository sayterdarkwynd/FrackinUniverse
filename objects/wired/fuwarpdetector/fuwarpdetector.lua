function init()
  self.flyingOutputStates = config.getParameter("flyingOutputStates")
end

function update(dt)
  local newFlyingType = world.flyingType()
  if newFlyingType ~= storage.flyingType then
    object.setOutputNodeLevel(1, self.flyingOutputStates[newFlyingType])
    object.setOutputNodeLevel(0, not(self.flyingOutputStates[newFlyingType]))
	
    storage.flyingType = newFlyingType
  end
end

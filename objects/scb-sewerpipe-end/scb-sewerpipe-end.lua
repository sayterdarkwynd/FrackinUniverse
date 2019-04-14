require "/scripts/vec2.lua"

function init()
  storage.timer = storage.timer or 0
  storage.location = {0, 0}
  local material = "metamaterial:scb-emptytile"

  if storage.active == nil then
    updateActive()
  end

  object.setMaterialSpaces( { {storage.location, material} } ) -- To connect to the pipe

  local enableCollision = config.getParameter("enableCollision")
  if enableCollision then
    physics.setCollisionEnabled(enableCollision, true)
  end
  -- Note to self, find a less redundant way of having tiles that particles can pass through?

end

function update(dt)
  if storage.active then
    storage.timer = storage.timer - dt
  end
end

function onNodeConnectionChange(args)
  updateActive()
end

function onInputNodeChange(args)
  updateActive()
end

function die()
  object.setMaterialSpaces( { } )
end

function updateActive()
  local active = (not object.isInputNodeConnected(0)) or object.getInputNodeLevel(0)
  if active ~= storage.active then
    storage.active = active
    if active then
      storage.timer = 0
      animator.setAnimationState("dripping", "on")
    else
      animator.setAnimationState("dripping", "off")
    end
  end
end

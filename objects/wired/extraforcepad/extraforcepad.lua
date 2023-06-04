function init()
  updateActive()
end

function onInputNodeChange(args)
  updateActive()
end

function onNodeConnectionChange(args)
  updateActive()
end

function updateActive()
  local active = not object.isInputNodeConnected(0) or object.getInputNodeLevel(0)
  physics.setForceEnabled("jumpForce", active)
  animator.setAnimationState("padState", active and "on" or "off")
end

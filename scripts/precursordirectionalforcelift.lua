function init()
  if storage.state == nil then storage.state = config.getParameter("defaultLightState", true) end

  self.interactive = config.getParameter("interactive", true)
  object.setInteractive(self.interactive)

  if config.getParameter("inputNodes") then
    processWireInput()
  end

  setLiftState(storage.state)
end

function onInputNodeChange(args)
  processWireInput()
end

function onNodeConnectionChange(args)
  processWireInput()
end

function onInteraction(args)
  if not config.getParameter("inputNodes") or not object.isInputNodeConnected(0) then
    storage.state = not storage.state
    setLiftState(storage.state)
  end
end

function processWireInput()
  if object.isInputNodeConnected(0) then
    object.setInteractive(false)
    storage.state = object.getInputNodeLevel(0)
    setLiftState(storage.state)
  elseif self.interactive then
    object.setInteractive(true)
  end
end

function setLiftState(newState)
  if newState then
	physics.setForceEnabled("liftForceUp", true)
	physics.setForceEnabled("liftForceDown", false)
	animator.setAnimationState("liftState", "up")
	animator.setParticleEmitterActive("up", true)
	animator.setParticleEmitterActive("down", false)
  else
	physics.setForceEnabled("liftForceUp", false)
	physics.setForceEnabled("liftForceDown", true)
	animator.setAnimationState("liftState", "down")
	animator.setParticleEmitterActive("up", false)
	animator.setParticleEmitterActive("down", true)
  end
end

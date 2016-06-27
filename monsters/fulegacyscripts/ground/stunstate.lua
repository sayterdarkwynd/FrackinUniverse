stunState = {
  duration = 1.5
}

function stunState.enterWith(params)
  if not params.stun then return nil end

return { timer = 0, duration = params.duration or stunState.duration }
end

function stunState.enteringState(stateData)
  entity.setParticleEmitterActive("stun", true)
end

function stunState.update(dt, stateData)
  entity.setAnimationState("attack", "idle")
  entity.setAnimationState("movement", "knockout")

  stateData.timer = stateData.timer + dt
  return stateData.timer > stateData.duration
end

function stunState.leavingState(stateData)
  entity.setParticleEmitterActive("stun", false)
end

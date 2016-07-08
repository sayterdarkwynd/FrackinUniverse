aggroHopState = {
  jumpForce = 0.25
}

function aggroHopState.enterWith(params)
  if not params.aggroHop then return nil end

  return { wasOffGround = false }
end

function aggroHopState.enteringState(stateData)
  animator.playSound("turnHostile")
end

function aggroHopState.update(dt, stateData)
  if mcontroller.onGround() then
    if stateData.wasOffGround then
      return true
    else
      faceTarget()
      mcontroller.setVelocity({0, aggroHopState.jumpForce * world.gravity(mcontroller.position())})
    end
  else
    stateData.wasOffGround = true
  end
end

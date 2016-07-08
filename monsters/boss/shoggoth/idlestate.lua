idleState = {}

function idleState.enter()
  if hasTarget() then return nil end
    animator.playSound("turnHostile")
  return {}
end

function idleState.update(dt, stateData)

end
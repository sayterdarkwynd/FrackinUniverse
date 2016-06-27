idleState = {}

function idleState.enter()
  if hasTarget() then return nil end
    entity.playSound("turnHostile")
  return {}
end

function idleState.update(dt, stateData)

end
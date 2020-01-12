idleState = {}

function idleState.enter()
  if hasTarget() then return nil end

  return {}
end

function idleState.update(dt, stateData)
  local toSpawn = world.distance(self.spawnPosition, mcontroller.position())
  if math.abs(toSpawn[1]) > 1 then
    move(toSpawn, true)
    animator.setAnimationState("movement", "move")
  else
    animator.setAnimationState("movement", "idle")
    mcontroller.controlFace(-1)
  end
end

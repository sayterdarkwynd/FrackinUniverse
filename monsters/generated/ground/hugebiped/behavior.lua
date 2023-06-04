function init()
  self.state = stateMachine.create({
    "moveState"
  })
  self.state.leavingState = function(stateName)
    entity.setAnimationState("movement", "idle")
  end

  entity.setAggressive(false)
  entity.setDeathParticleBurst("deathPoof")
  entity.setAnimationState("movement", "idle")
end

function update(dt)
  self.state.update(dt)
end

function damage(args)
  self.state.pickState(args.sourceId)
end

function move(direction)
  entity.setAnimationState("movement", "walk")

  mcontroller.controlMove(direction, false)
end

--------------------------------------------------------------------------------
moveState = {}

function moveState.enter()
  return {
    timer = 4,
    direction = util.randomDirection()
  }
end

function moveState.update(dt, stateData)
  move(stateData.direction)

  stateData.timer = stateData.timer - dt
  if stateData.timer <= 0 then
    return true
  end

  return false
end
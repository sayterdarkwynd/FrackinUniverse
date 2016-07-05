--------------------------------------------------------------------------------
dieState = {}

dieState.enterWith = function(params)
  if not params.die then return nil end
  
  rangedAttack.setConfig(entity.configParameter("projectiles.deathexplosion.type"), entity.configParameter("projectiles.deathexplosion.config"), 0.2)
  entity.playSound("turnHostile")
  return {
    timer = 6.0,
    basePosition = mcontroller.position()
  }
end

function dieState.enteringState(stateData)
  animator.setAnimationState("movement", "death")
end

dieState.update = function(dt, stateData)
  mcontroller.controlParameters({gravityEnabled = true})

  
  if stateData.timer <= 0.0 then
    self.dead = true
  end

  stateData.timer = stateData.timer - dt
  return false
end
gasTrailAttack = {
  fireTime = 0.5
}

function gasTrailAttack.enter()
  if not canStartSkill("gasTrailAttack") then return nil end

  return {fireTimer = 0.2, faceDirection = self.toTarget[1]} --give it a bit of time to back up and telegraph
end

function gasTrailAttack.enteringState(stateData)
  animator.setAnimationState("attack", "shooting")

  monster.setActiveSkillName("gasTrailAttack")
end

function gasTrailAttack.update(dt, stateData)
  if isBlocked() or not canContinueSkill() then return true end

  mcontroller.controlParameters({runSpeed=3.0})
  animator.setAnimationState("movement", "walk")

  moveX(-stateData.faceDirection, true)
  mcontroller.controlFace(stateData.faceDirection)

  if stateData.fireTimer <= 0 then
    gasTrailAttack.fire()
    stateData.fireTimer = gasTrailAttack.fireTime
  end

  stateData.fireTimer = stateData.fireTimer - dt

  return false
end

function gasTrailAttack.leavingState(stateData)
end

function gasTrailAttack.fire()
  local projectileStartPosition = monster.toAbsolutePosition({config.getParameter("projectileSourcePosition", {0, 0})[1] + 1.0, config.getParameter("projectileSourcePosition", {0, 0})[2]})
  local projectileName = config.getParameter("gasTrailAttack.projectile")
  world.spawnProjectile(projectileName, projectileStartPosition, entity.id(), {mcontroller.facingDirection(), 0}, false, {speed = 0, timeToLive = 1.8, animationCycle = 1.8})
end

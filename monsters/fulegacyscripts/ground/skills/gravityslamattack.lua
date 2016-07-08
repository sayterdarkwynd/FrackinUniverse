gravitySlamAttack = {
  minDistance = 3,
  maxMoveTime = 4,
  liftMultiplier = 3,
  baseDamage = 5,
}

function gravitySlamAttack.enter()
  if not canStartSkill("gravitySlamAttack") then return nil end

  return { run = coroutine.wrap(gravitySlamAttack.run) }
end

function gravitySlamAttack.enteringState(stateData)
  animator.setAnimationState("movement", "idle")
  animator.setAnimationState("attack", "idle")

  monster.setActiveSkillName("gravitySlamAttack")
end

function gravitySlamAttack.update(dt, stateData)
  if not hasTarget() then return true end

  return stateData.run(stateData)
end

function gravitySlamAttack.leavingState(stateData)
  animator.setParticleEmitterActive("gravitySlamAttackUp", false)
  animator.setParticleEmitterActive("gravitySlamAttackDown", false)
end

function gravitySlamAttack.run(stateData)
  mcontroller.controlFace(self.toTarget[1])
  animator.setAnimationState("movement", "idle")
  animator.setAnimationState("attack", "charge")

  animator.setParticleEmitterActive("gravitySlamAttackUp", true)

  util.wait(0.6, function()
    world.spawnProjectile("grabbed", world.entityPosition(self.target), entity.id(), { 0, 0 }, false)

    local gravity = world.gravity(world.entityPosition(self.target))
    gravitySlamAttack.applyVerticalForceToTarget(gravity * gravitySlamAttack.liftMultiplier)
  end)

  animator.setParticleEmitterActive("gravitySlamAttackUp", false)
  animator.setParticleEmitterActive("gravitySlamAttackDown", true)

  util.wait(0.2, function()
    world.spawnProjectile("grabbed", world.entityPosition(self.target), entity.id(), { 0, 0 }, false)

    local gravity = world.gravity(world.entityPosition(self.target))
    gravitySlamAttack.applyVerticalForceToTarget(-gravity)
  end)

  util.wait(0.5, function()
    world.spawnProjectile("grabbed", world.entityPosition(self.target), entity.id(), { 0, 0 }, false)

    gravitySlamAttack.applyVerticalForceToTarget(-600)
  end)

  return true
end

function gravitySlamAttack.applyVerticalForceToTarget(amount)
  local targetPosition = world.entityPosition(self.target)
  local region = {
    targetPosition[1] - 1, targetPosition[2] - 3,
    targetPosition[1] + 1, targetPosition[2] + 3,
  }
  entity.setForceRegion(region, { 0, amount } )
end

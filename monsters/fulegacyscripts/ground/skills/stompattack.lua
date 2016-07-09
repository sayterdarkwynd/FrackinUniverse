stompAttack = {
  windupTime = 0.2,
  jumpTime = 0,
  forceDelay = 0.2,
  maxLandWaitTime = 4,
  cooldownTime = 1,
  stompForce = 200,
  baseDamage = 15,
  projectileOffsetX = 1,
}

function stompAttack.enter()
  if not canStartSkill("stompAttack") then return nil end
  return { run = coroutine.wrap(stompAttack.run) }
end

function stompAttack.enteringState(stateData)
  animator.setAnimationState("movement", "idle")
  animator.setAnimationState("attack", "idle")

  monster.setActiveSkillName("stompAttack")
end

function stompAttack.update(dt, stateData)
  if not hasTarget() then return true end
  return stateData.run(stateData)
end

function stompAttack.run(stateData)
  animator.setAnimationState("movement", "chargeWindup")
  mcontroller.controlFace(self.toTarget[1])
  util.wait(stompAttack.windupTime)

  animator.setAnimationState("movement", "jump")
  controlJump()
  coroutine.yield(false)

  local forceTimer = stompAttack.forceDelay
  util.wait(stompAttack.maxLandWaitTime, function(dt)
    if mcontroller.onGround() then return true end

    if forceTimer <= 0 then
      mcontroller.controlForce({ 0, -stompAttack.stompForce })
    end
    forceTimer = forceTimer - dt
  end)

  local entityId = entity.id()
  local power = stompAttack.baseDamage * monster.level() / 2
  local bounds = config.getParameter("metaBoundBox")
  world.spawnProjectile("defensiveexplosion", monster.toAbsolutePosition({ bounds[1] - stompAttack.projectileOffsetX, bounds[2] }), entityId, { -1, 0 }, false, { power = power })
  world.spawnProjectile("defensiveexplosion", monster.toAbsolutePosition({ bounds[3] + stompAttack.projectileOffsetX, bounds[2] }), entityId, { 1, 0 }, false, { power = power })

  animator.setAnimationState("movement", "idle")
  util.wait(stompAttack.cooldownTime)

  return true
end

function stompAttack.leavingState(stateData)
end

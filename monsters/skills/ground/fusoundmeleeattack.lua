fuSoundMeleeAttack = {}

--allow force entering state without canStartSkill
function fuSoundMeleeAttack.enterWith(args)
  if not args.fuSoundMeleeAttack then return nil end

  return { didAttack = false, wasInRange = false }
end

function fuSoundMeleeAttack.enter()
  if not canStartSkill("fuSoundMeleeAttack") then return nil end

  return { didAttack = false, wasInRange = false }
end

function fuSoundMeleeAttack.enteringState(stateData)
  setAggressive(true, false)
  animator.setAnimationState("attack", "melee")

  stateData.projectileSourcePosition = {
      config.getParameter("projectileSourcePosition", {0, 0})[1] + config.getParameter("meleeProjectileOffset", {0, 0})[1] - 1.0,
      config.getParameter("projectileSourcePosition", {0, 0})[2] + config.getParameter("meleeProjectileOffset", {0, 0})[2]
    }

  monster.setActiveSkillName("fuSoundMeleeAttack")
end

function fuSoundMeleeAttack.update(dt, stateData)
  if not canContinueSkill() then return true end

  animator.setAnimationState("movement", "run")

  local attackCompletion = (config.getParameter("fuSoundMeleeAttack.skillTimeLimit") - self.skillTimer) / config.getParameter("fuSoundMeleeAttack.skillTimeLimit")

  local baseRunSpeed = mcontroller.baseParameters().runSpeed

  if baseRunSpeed < 11.0 then
    mcontroller.controlParameters({runSpeed=11.0})
  elseif baseRunSpeed > 15.0 then
    mcontroller.controlParameters({runSpeed=15.0})
  end

  mcontroller.controlParameters({groundForce=50})

  -- if attackCompletion <= 0.5 then
  --   moveX(self.toTarget[1])
  -- else
  --   moveX(-self.toTarget[1])
  -- end

  -- if attackCompletion <= 0.25 or attackCompletion >= 0.75 then
  --   entity.applyMovementParameters({runSpeed=10.0})
  -- else
  --   entity.applyMovementParameters({runSpeed=7.0})
  -- end

  if stateData.wasInRange == false and math.abs(self.toTarget[1]) > math.abs(config.getParameter("projectileSourcePosition", {0, 0})[1]) + 1.0 then
    moveX(self.toTarget[1], true)
  else
    stateData.wasInRange = true
    moveX(-self.toTarget[1], true)
  end
  mcontroller.controlFace(self.toTarget[1])

  if stateData.didAttack == false and attackCompletion >= 0.25 then
    local projectileStartPosition = monster.toAbsolutePosition(stateData.projectileSourcePosition)
    local projectileName = config.getParameter("meleeProjectile") or config.getParameter("fuSoundMeleeAttack.projectile")
    local power = root.evalFunction("monsterLevelPowerMultiplier", monster.level()) * config.getParameter("fuSoundMeleeAttack.power")
    animator.playSound("attack")
    world.spawnProjectile(projectileName, projectileStartPosition, entity.id(), {mcontroller.facingDirection(), 0}, true, {speed = 7.0, power = power})
    stateData.didAttack = true
  end

  return false
end

function fuSoundMeleeAttack.leavingState(stateData)

end

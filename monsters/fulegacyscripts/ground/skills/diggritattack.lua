digGritAttack = {
  minDistance = 3,
  maxDistance = 9,
  maxMoveInRangeTime = 3,
  digTime = 2
}

--------------------------------------------------------------------------------
function digGritAttack.enter()
  if not canStartSkill("digGritAttack") then return nil end

  return { run = coroutine.wrap(digGritAttack.run) }
end

--------------------------------------------------------------------------------
function digGritAttack.enteringState(stateData)
  animator.setAnimationState("movement", "idle")
  animator.setAnimationState("attack", "idle")

  monster.setActiveSkillName("digGritAttack")
end

--------------------------------------------------------------------------------
function digGritAttack.update(dt, stateData)
  if not canContinueSkill() then return true end

  return stateData.run(stateData)
end

--------------------------------------------------------------------------------
function digGritAttack.run(stateData)
  animator.setAnimationState("movement", "run")

  local feetOffset = mcontroller.boundBox()[2]

  local timer, projectileTimer = digGritAttack.digTime, config.getParameter("digGritAttack.fireInterval")
  while timer > 0 do
    mcontroller.controlFace(-self.toTarget[1])

    if projectileTimer < 0 then
      local sourcePosition = vec2.add(mcontroller.position(), { 0, mcontroller.boundBox()[2] + 0.5})
      local toTarget = world.distance(world.entityPosition(self.target), sourcePosition)
      local fireVector = util.aimVector(toTarget, config.getParameter("digGritAttack.speed"), root.projectileGravityMultiplier("rock"), true)
      world.spawnProjectile("rock", sourcePosition, entity.id(), fireVector, false, {
        speed = config.getParameter("digGritAttack.speed"),
        power = root.evalFunction("monsterLevelPowerMultiplier", monster.level()) * config.getParameter("digGritAttack.power"),
        physics = "bullet",
        actionOnReap = {
          {
            action = "tile",
            materials = {
              { kind = "sand" }
            },
            allowEntityOverlap = true
          }
        }
      })
      projectileTimer = config.getParameter("digGritAttack.fireInterval")
    end

    local dt = script.updateDt()
    projectileTimer = projectileTimer - dt
    timer = timer - dt

    coroutine.yield(false)
  end

  return true
end

--------------------------------------------------------------------------------
function digGritAttack.wait(duration, action)
  local timer = 0
  while timer < duration do
    if action ~= nil then action() end

    timer = timer + script.updateDt()
    coroutine.yield(false)
  end
end

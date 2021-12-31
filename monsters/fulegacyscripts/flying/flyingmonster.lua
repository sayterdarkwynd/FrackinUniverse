require "/scripts/util.lua"

function init()
  self.position = {0, 0}

  self.target = 0
  self.toTarget = {0, 0}

  self.aggressive = config.getParameter("aggressive", false)
  setAggressive(false, false)

  self.targetSearchTimer = 0
  self.targetHoldTimer = 0
  self.attackCooldownTimer = 0

  self.sensors = sensors.create()

  self.debug = false

  local scripts = config.getParameter("scripts")

  local states = stateMachine.scanScripts(scripts, "(%a+State)%.lua")
  self.state = stateMachine.create(states)

  local attacks = {}
  local attackStateTables = {}
  for i, skillName in ipairs(config.getParameter("skills")) do
    local params = config.getParameter(skillName)

    --create generic attacks from factories
    if params and params.factory then
      if type(_ENV[params.factory]) == "function" then
        if not _ENV[skillName] then
          _ENV[skillName] = _ENV[params.factory](skillName)
        else
          sb.logInfo("Failed to create attack %s from factory %s: Table %s already exists in this context", skillName, params.factory, skillName)
        end
      else
        sb.logInfo("Failed to create attack %s from factory %s: factory function does not exist in this context", skillName, params.factory)
      end
    end

    if _ENV[skillName] then
      table.insert(attacks, 1, skillName)
    end
  end

  self.attackState = stateMachine.create(attacks, attackStateTables)
  self.attackState.autoPickState = false

  self.attackState.enteringState = function(state)
    monster.setActiveSkillName(state)
    setAggressive(true)
    self.attackState.moveStateToEnd(state)
  end

  self.attackState.leavingState = function(state)
    setAggressive(false)
    monster.setActiveSkillName(nil)
    self.attackCooldownTimer = config.getParameter("attackCooldownTime")
  end

  monster.setDeathSound("deathPuff")
  monster.setDeathParticleBurst(config.getParameter("deathParticles"))

  mcontroller.controlFace(util.randomDirection())
  animator.setAnimationState("movement", "flying")
end

function isFlyer()
  return true
end

function damage(args)
  setTarget(args.sourceId)

  if status.resource("health") > 0 then
    self.state.endState()
  end
end

function setAggressive(enabled)
  if enabled then
    monster.setAggressive(true)
    monster.setDamageOnTouch(true)
    self.aggressive = true
  else
    monster.setDamageOnTouch(config.getParameter("alwaysDamageOnTouch", false))
    monster.setAggressive(self.aggressive)
  end
end

function update(dt)
  self.position = mcontroller.position()

  local stuns = status.statusProperty("stuns", {})
  local slows = status.statusProperty("slows", {})

  local stunned = false
  if next(stuns) then
    stunned = true
    animator.setAnimationRate(0)
  end
  if not stunned then
    local animSpeed = 1.0
    for k, v in pairs(slows) do
      animSpeed = animSpeed * v
    end
    animator.setAnimationRate(animSpeed)
  end

  if stunned then
    --do nothing
  else
    if animator.animationState("movement") ~= "flyingAttack" and animator.animationState("movement") ~= "gliding" then
      animator.setAnimationState("movement", "flying")
    end

    trackTarget()

    -- Attacks can interrupt any normal state
    if self.target ~= 0 then
      if attacking() then
        local attackMaxDistance = config.getParameter("attackMaxDistance", math.huge)

        if world.magnitude(self.toTarget) > attackMaxDistance then
          self.attackState.endState()
        else
          self.attackState.update(dt)
        end
      else
        local attackStartDistance = config.getParameter("attackStartDistance")

        if world.magnitude(self.toTarget) <= attackStartDistance and self.attackCooldownTimer <= 0 then
          self.attackState.pickState()
        end
      end
    end

    if not attacking() then
      setAggressive(false)
      self.state.update(dt)
    end
  end

  decrementTimers()

  script.setUpdateDelta(hasTarget() and 1 or 10)

  if self.debug then
    if attacking() then
      world.debugText(self.attackState.stateDesc(), monster.toAbsolutePosition({ 0, 2 }), "red")
    elseif self.state.hasState() then
      world.debugText(self.state.stateDesc(), monster.toAbsolutePosition({ 0, 2 }), "blue")
    end

    for i, groundSensorIndex in ipairs({ 3, 2, 1 }) do
      local sensor = self.sensors.groundSensors.collisionTrace[groundSensorIndex]
      if sensor.value then
        util.debugLine(mcontroller.position(), sensor.position, "green")
        world.debugPoint(sensor.position, "green")
      else
        util.debugLine(mcontroller.position(), sensor.position, "red")
        world.debugPoint(sensor.position, "red")
      end
    end
  end

  self.sensors.clear()
end

function trackTarget()
  -- Keep holding on our target while we are attacking
  if not world.entityExists(self.target) or (not attacking() and self.targetHoldTimer <= 0) then
    setTarget(0)
  end

  if self.aggressive and self.target == 0 and self.targetSearchTimer <= 0 then
    setTarget(util.closestValidTarget(config.getParameter("targetRadius")))
    self.targetSearchTimer = config.getParameter("targetSearchTime")
  end

  if self.target == 0 then
    self.toTarget = {0, 0}
  else
    self.toTarget = entity.distanceToEntity(self.target)
  end
end

function setTarget(target)
  if target ~= 0 then
    self.targetHoldTimer = config.getParameter("targetHoldTime")

    if self.target ~= target then
      animator.playSound("turnHostile")

      -- Don't attack immediately when turning aggressive
      self.attackCooldownTimer = config.getParameter("attackCooldownTime")
    end
  end

  self.target = target
end

function hasTarget()
  return self.target ~= 0
end

function decrementTimers()
  dt = script.updateDt()

  self.targetSearchTimer = self.targetSearchTimer - dt
  self.targetHoldTimer = self.targetHoldTimer - dt
  self.attackCooldownTimer = self.attackCooldownTimer - dt
end

function attacking()
  return self.attackState.hasState()
end

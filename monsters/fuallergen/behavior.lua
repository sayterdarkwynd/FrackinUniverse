function init(args)
  self.dead = false
  self.sensors = sensors.create()

  self.state = stateMachine.create({
    "idleState",
    "shootState",
  })
  self.state.leavingState = function(stateName)
    animator.setAnimationState("default", "idle")
  end

  monster.setDamageOnTouch(true)
  monster.setAggressive(true)
  animator.setAnimationState("default", "idle")
end

function update(dt)
  if util.trackTarget(config.getParameter("shoot.seedShotDistance")) then
    self.state.pickState({ targetId = self.targetId })
  end
  self.state.update(dt)
  self.sensors.clear()
end

function damage(args)
  if status.resource("health") <= 0 then
    self.state.pickState({ die = true })
  else
    self.state.pickState({ targetId = args.sourceId })
  end
end

--------------------------------------------------------------------------------
idleState = {}

function idleState.enter()
  return { }
end

function idleState.update(dt, stateData)
  animator.setAnimationState("default", "idle")

  return true
end

--------------------------------------------------------------------------------
shootState = {}

function shootState.enterWith(args)
  if args.targetId == nil then return nil end
  
  local targetPosition = world.entityPosition(args.targetId)
  if targetPosition == nil then return nil end

  return {
    targetId = args.targetId,
    targetPosition = targetPosition,
    shotFired = false,
    timer = config.getParameter("shoot.fireTime"),
    recoilTimer = config.getParameter("shoot.recoilTime"),
  }
end

function shootState.update(dt, stateData)
  animator.setAnimationState("default", "shoot")

  stateData.timer = stateData.timer - dt
  if stateData.timer <= 0 then
    if not stateData.shotFired then
      local randDir = math.random() * math.pi -- 0 to pi
      local direction = {
        math.cos(randDir),
        math.sin(randDir)
      }
      local oldTid = self.targetId
      self.targetId = nil
      if util.trackTarget(config.getParameter("shoot.pollenShotDistance")) then
         --entity.setFireDirection({0, 0}, direction)
         --entity.startFiring("pollen")
      else
        self.targetId = oldTid
         --entity.setFireDirection({0, 0}, direction)
         --entity.startFiring("seed")
      end
      stateData.shotFired = true
    else
       --entity.stopFiring()
    end
    stateData.recoilTimer = stateData.recoilTimer - dt
  end

  if stateData.recoilTimer <= 0 then
    self.targetId = nil
    return true
  end

  return false
end

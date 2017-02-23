require "/scripts/util.lua"

function init()
  self.dead = false
  self.targetId = nil

  self.state = stateMachine.create({
    "moveState",
    "attackState",
    "captiveState"
  })
  self.state.leavingState = function(stateName)
    animator.setAnimationState("movement", util.randomFromList(config.getParameter("idleAnimations")))
  end

  monster.setAggressive(false)
  monster.setDeathParticleBurst("deathPoof")

  capturepod.onInit()

  self.movement = groundMovement.create(1, 1, function(animationState)
    animator.setAnimationState("movement", "move")
  end)
end

--------------------------------------------------------------------------------
function update(dt)
  self.state.update(dt)
end

--------------------------------------------------------------------------------
function damage(args)
  if not capturepod.onDamage(args) then
    self.state.pickState(args.sourceId)
  end
end

--------------------------------------------------------------------------------
-- Called when a monster has been killed, on the entity that dealt the death-blow
function monsterKilled(entityId)
  capturepod.onMonsterKilled()
end

--------------------------------------------------------------------------------
function die()
  capturepod.onDie()
end

--------------------------------------------------------------------------------
function shouldDie()
  return self.dead or status.resource("health") <= 0
end

--------------------------------------------------------------------------------
moveState = {}

function moveState.enter()
  if capturepod.isCaptive() then return nil end

  return {
    timer = util.randomInRange(config.getParameter("moveTimeRange")),
    direction = util.randomDirection()
  }
end

function moveState.update(dt, stateData)
  if not self.movement.move(mcontroller.position(), stateData.direction, false, stateData.running) then
    stateData.direction = -stateData.direction
  end

  stateData.timer = stateData.timer - dt
  if stateData.timer <= 0 then
    return true, util.randomInRange(config.getParameter("idleTimeRange"))
  end

  return false
end

--------------------------------------------------------------------------------
attackState = {}

function attackState.enterWith(targetId)
  if targetId == 0 then return nil end

  attackState.setAggressive(targetId)

  return { timer = config.getParameter("attackTargetHoldTime") }
end

function attackState.update(dt, stateData)
  util.trackExistingTarget()

  if self.attackHoldTimer ~= nil then
    self.attackHoldTimer = self.attackHoldTimer - dt
    if self.attackHoldTimer > 0 then
      return false
    else
      self.attackHoldTimer = nil
    end
  end

  if self.targetPosition ~= nil then
    local position = mcontroller.position()
    local toTarget = world.distance(self.targetPosition, mcontroller.position())

    if world.magnitude(toTarget) < config.getParameter("attackDistance") then
      attackState.setAttackEnabled(true)
    else
      attackState.setAttackEnabled(false)
      self.movement.move(position, util.toDirection(toTarget[1]), true, stateData.running)
    end
  end

  if self.targetId == nil then
    stateData.timer = stateData.timer - dt
  else
    stateData.timer = config.getParameter("attackTargetHoldTime")
  end

  if stateData.timer <= 0 then
    attackState.setAttackEnabled(false)
    attackState.setAggressive(nil)
    return true
  else
    return false
  end
end

function attackState.setAttackEnabled(enabled)
  if enabled then
    animator.setAnimationState("movement", "attack")
    self.attackHoldTimer = config.getParameter("attackHoldTime")
  else
  end

end

function attackState.setAggressive(targetId)
  self.targetId = targetId

  if targetId ~= nil then
    monster.setAggressive(true)
  else
    animator.setAnimationState("movement", "idle")
    monster.setAggressive(false)
  end
end

function attackState.hasTarget()
  return self.targetId ~= nil
end

--------------------------------------------------------------------------------
captiveState = {
  closeDistance = 4,
  runDistance = 12,
  teleportDistance = 36,
}

function captiveState.enter()
  if not capturepod.isCaptive() or attackState.hasTarget() then return nil end

  return { running = false }
end

function captiveState.enterWith(params)
  if not capturepod.isCaptive() then return nil end

  return { running = false }
end

function captiveState.update(dt, stateData)
  if attackState.hasTarget() then return true end

  if not capturepod.updateOwnerEntityId() then
    -- Owner is nowhere around
    return false
  end

  local position = mcontroller.position()
  local ownerPosition = world.entityPosition(self.ownerEntityId)
  local toOwner = world.distance(ownerPosition, position)
  local distance = math.abs(toOwner[1])

  local movement
  if distance > captiveState.teleportDistance then
    movement = 0
    mcontroller.setPosition(ownerPosition)
  elseif distance < captiveState.closeDistance then
    stateData.running = false
    movement = 0
  elseif toOwner[1] < 0 then
    movement = -1
  elseif toOwner[1] > 0 then
    movement = 1
  end

  if distance > captiveState.runDistance then
    stateData.running = true
  end

  if movement ~= 0 then
    self.movement.move(position, movement, true, stateData.running)
  else
    local animation = animator.animationState("movement")
    local playingIdleAnimation = false
    for _, idleAnimation in pairs(config.getParameter("idleAnimations")) do
      playingIdleAnimation = playingIdleAnimation or idleAnimation == animation
    end

    if not playingIdleAnimation then
      animator.setAnimationState("movement", util.randomFromList(config.getParameter("idleAnimations")))
    end
  end

  return false
end

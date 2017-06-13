require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/scripts/drops.lua"
require "/scripts/status.lua"

-- Engine callback - called on initialization of entity
function init()
  self.shouldDie = true

  if animator.hasSound("deathPuff") then
    monster.setDeathSound("deathPuff")
  end
  if config.getParameter("deathParticles") then
    monster.setDeathParticleBurst(config.getParameter("deathParticles"))
  end

  script.setUpdateDelta(5)

  self.targets = {}
  self.queryRange = config.getParameter("queryRange", 50)
  self.keepTargetInRange = config.getParameter("keepTargetInRange", 200)

  -- Listen to damage taken for getting stunned and suppressing damage
  self.damageTaken = damageListener("damageTaken", function(notifications)
    for _,notification in pairs(notifications) do
      if notification.healthLost > 0 then
        if not contains(self.targets, notification.sourceEntityId) then
          table.insert(self.targets, notification.sourceEntityId)
        end
        self.damaged = true
      end
    end
  end)

  -- set self.frontgun and self.backgun to coroutines controlling each gun
  -- max range will be the lowest range of either gun
  self.maxRange = 9999 -- very big number
  for _,gunPart in pairs({"frontgun", "backgun"}) do
    local gunConfig = config.getParameter(gunPart)
    self[gunPart] = coroutine.create(controlGun)
    local status, res = coroutine.resume(self[gunPart],
      gunPart,
      gunConfig.offset,
      gunConfig.projectileType,
      gunConfig.projectileParameters or {},
      gunConfig.count,
      gunConfig.power,
      gunConfig.fireInterval,
      gunConfig.fireCooldown,
      gunConfig.range
    )
    if not status then
      error(res)
    end

    if gunConfig.range < self.maxRange then
      self.maxRange = gunConfig.range
    end
  end

  local approachPadding = config.getParameter("approachPadding", 5)
  local tangentialSpeed = config.getParameter("tangentialSpeed", 15)
  self.movement = coroutine.create(approachOrbit)
  local status, res = coroutine.resume(self.movement, self.maxRange - approachPadding, tangentialSpeed, 20)
  if not status then error(res) end


  monster.setName("Heavy War Drone")
  monster.setDamageBar("special") 
  
  self.switchAngleTime = config.getParameter("switchAngleTime")
end

function update(dt)
  self.damageTaken:update()

  if status.resourcePositive("stunned") then
    animator.setAnimationState("damage", "stunned")
    mcontroller.clearControls()
    if self.damaged then
      self.suppressDamageTimer = config.getParameter("stunDamageSuppression", 0.5)
      monster.setDamageOnTouch(false)
    end
    return
  else
    animator.setAnimationState("damage", "none")
  end

  -- Suppressing touch damage
  if self.suppressDamageTimer then
    monster.setDamageOnTouch(false)
    self.suppressDamageTimer = math.max(self.suppressDamageTimer - dt, 0)
    if self.suppressDamageTimer == 0 then
      self.suppressDamageTimer = nil
    end
  elseif status.statPositive("invulnerable") then
    monster.setDamageOnTouch(false)
  else
    monster.setDamageOnTouch(true)
  end

  -- query for new targets if there are none
  if #self.targets == 0 then
    local newTargets = world.entityQuery(mcontroller.position(), self.queryRange, {includedTypes = {"player"}})
    table.sort(newTargets, function(a, b)
      return world.magnitude(world.entityPosition(a), mcontroller.position()) < world.magnitude(world.entityPosition(b), mcontroller.position())
    end)
    for _,entityId in pairs(newTargets) do
      table.insert(self.targets, entityId)
    end
  end

  -- drop targets out of range, keep current target the top of the targets list
  repeat
    self.target = self.targets[1]
    if self.target == nil then break end

    if not world.entityExists(self.target) or
       world.magnitude(world.entityPosition(self.target), mcontroller.position()) > self.keepTargetInRange then
      table.remove(self.targets, 1)
      self.target = nil
    end
  until #self.targets <= 0 or self.target

  -- update the guns
  for _,gunState in pairs({self.frontgun, self.backgun}) do
    local status, res = coroutine.resume(gunState)
    if not status then
      error(res)
    end
  end

  if self.target then
    local toTarget = world.distance(world.entityPosition(self.target), mcontroller.position())
    mcontroller.controlFace(util.toDirection(toTarget[1]))

    local status, res = coroutine.resume(self.movement, dt)
    if not status then error(res) end
  end
end

-- keeps aiming and firing, run in a coroutine
function controlGun(part, offset, projectileType, params, count, power, interval, cooldown, range)

  -- everything before the first yield is initialization
  coroutine.yield()
  while true do
    local cooldownOffset = math.random() * cooldown

    if self.target then
      local center, targetPosition, toTarget
      local updateTargetPos = function()
        animator.resetTransformationGroup(part)
        center = animator.partPoint(part, "rotationCenter")
        if part == "frontgun" then
          world.debugPoint(vec2.add(mcontroller.position(), center), "yellow")
        end
        targetPosition = world.entityPosition(self.target)
        if targetPosition == nil then return true end

        toTarget = world.distance(targetPosition, vec2.add(mcontroller.position(), center))
        local rotateAngle = vec2.angle(vec2.mul(toTarget, {mcontroller.facingDirection(), 1}))
        animator.rotateTransformationGroup(part, rotateAngle, vec2.mul(center, {mcontroller.facingDirection(), 1}))
      end

      updateTargetPos()
      while self.target and targetPosition and world.magnitude(targetPosition, mcontroller.position()) < range do
        -- update target position during cooldown
        util.wait(cooldownOffset, updateTargetPos)
        if targetPosition == nil then break end

        local shots = 0
        while shots < count do
          local aimVector = vec2.norm(toTarget)
          local source = vec2.add(mcontroller.position(), vec2.add(center, vec2.rotate(offset, vec2.angle(toTarget))))
          local scaledPower = power * root.evalFunction("monsterLevelPowerMultiplier", monster.level())
          params.power = scaledPower
          world.spawnProjectile(projectileType, source, entity.id(), aimVector, false, params)
          shots = shots + 1
          animator.playSound("fire")
          util.wait(interval)
        end

        util.wait(cooldown - cooldownOffset, updateTargetPos)
      end
    end

    coroutine.yield()
  end
end

function approachOrbit(distance, maxTangential)
  local tangentialSpeed = 0
  local dt = coroutine.yield()
  while true do
    local approachAngle = math.random() * math.pi * 2

    util.wait(self.switchAngleTime, function()
      if not self.target then return true end
      local targetPosition = world.entityPosition(self.target)
      local targetVelocity = world.entityVelocity(self.target)

      local toTarget = world.distance(targetPosition, mcontroller.position())
      local approachPoint = vec2.add(targetPosition, vec2.mul(toTarget, -1))
      local toApproach = vec2.norm(world.distance(approachPoint, mcontroller.position()))
      local approach = vec2.add(vec2.mul(toApproach, math.min(vec2.mag(toApproach) ^ 3, mcontroller.baseParameters().flySpeed)), targetVelocity)

      local toOrbit
      if vec2.mag(toTarget) > distance then
        local toEdge = math.sqrt((vec2.mag(toTarget) ^ 2) - (distance ^ 2))
        local toEdgeAngle = math.atan(distance, toEdge)
        toOrbit = vec2.withAngle(toEdgeAngle)
      else
        toOrbit = {0, 1}
      end

      local targetAngle = vec2.angle(toTarget)
      local leadDir = util.toDirection(util.angleDiff(targetAngle, approachAngle))
      local tangentialSpeed = leadDir * maxTangential
      local tangentialApproach = vec2.mul(vec2.rotate({toOrbit[1], toOrbit[2] * util.toDirection(tangentialSpeed)}, targetAngle), math.abs(tangentialSpeed))
      approach = vec2.add(approach, tangentialApproach)

      mcontroller.controlApproachVelocity(approach, mcontroller.baseParameters().airForce, true)
      if approach[1] * mcontroller.facingDirection() > 0 then
        animator.setAnimationState("body", "forward")
      else
        animator.setAnimationState("body", "back")
      end
    end)

    coroutine.yield()
  end
end

function shouldDie()
  return self.shouldDie and status.resource("health") <= 0
end

function die()
  animator.playSound("deathPuff")
  world.spawnProjectile("mechenergypickup", mcontroller.position())
  spawnDrops()
end

function uninit()
end

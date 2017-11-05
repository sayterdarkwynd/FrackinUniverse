function init()
  self.minRange = config.getParameter("minRange") or 0.5

  self.visualProjectileType = config.getParameter("visualProjectileType")
  self.visualProjectileCount = config.getParameter("visualProjectileCount") or 20
  self.visualProjectileSpeed = config.getParameter("visualProjectileSpeed") or 20
  self.visualProjectileTime = config.getParameter("visualProjectileTime")
  self.visualDuration = config.getParameter("visualDuration") or 0.2

  self.damageProjectileType = config.getParameter("damageProjectileType") or "armorthornburst"
  self.damageMultiplier = config.getParameter("damageMultiplier") or 0.01
  self.border = config.getParameter("border")

  self.cooldown = config.getParameter("cooldown") or 5

  self.removeInWater = config.getParameter("removeInWater")

  self.minTriggerDamage = config.getParameter("minTriggerDamage") or 0

  resetThorns()
  self.cooldownTimer = 0

  --if self.border then
  --  effect.setParentDirectives("border="..self.border)
  --end

  self.queryDamageSince = 0
end

function resetThorns()
  self.cooldownTimer = self.cooldown
  self.triggerThorns = false
  self.thornsTimer = 0
  self.spawnedThorns = 0
  self.thornDamage = 0
end

function update(dt)
  
  if self.cooldownTimer <= 0 then
    local damageNotifications, nextStep = status.damageTakenSince(self.queryDamageSince)
    self.queryDamageSince = nextStep
    for _, notification in ipairs(damageNotifications) do
      if notification.healthLost > self.minTriggerDamage and notification.sourceEntityId ~= notification.targetEntityId then
        triggerThorns(notification.healthLost * self.damageMultiplier)
        self.cooldownTimer = self.cooldown
        break
      end
    end
  end

  if self.removeInWater then
    if effect.duration() and world.liquidAt({mcontroller.xPosition(), mcontroller.yPosition() - 1}) then
      effect.expire()
    end
  end

  if self.cooldownTimer > 0 then
    self.cooldownTimer = self.cooldownTimer - dt
  end

  if self.triggerThorns then
    self.thornsTimer = self.thornsTimer - dt

    local fadeOpacity = ((self.visualProjectileCount - self.spawnedThorns) / self.visualProjectileCount) * 0.8
    if self.thornsTimer <= 0 then
      local thornCount
      local visualInterval = self.visualDuration / self.visualProjectileCount

      if not self.visualDuration or self.visualDuration <= 0 then
        thornCount = self.visualProjectileCount
      else
        --It's possible we need to spawn several thorns because they need to spawn very fast
        thornCount = math.floor((visualInterval - self.thornsTimer) / visualInterval)
        thornCount = math.min(thornCount, self.visualProjectileCount - self.spawnedThorns)
      end

      spawnVisualThorns(thornCount)

      self.thornsTimer = self.thornsTimer + thornCount * visualInterval

      if self.spawnedThorns >= self.visualProjectileCount then resetThorns() end
    end
  end
end

function spawnVisualThorns(count)
    if status.resource("energy") >=5 then
      self.energyCalculation = (status.resource("energy") / status.stat("maxEnergy") ) /2
      status.modifyResourcePercentage("energy", -self.energyCalculation)  
	  if count == nil then count = 1 end
	  local pi = 3.14

	  local randAngle = math.random() * 2 * pi --Random radian
	  local angleInterval = math.pi * 2 / count
	  for x = 0, count - 1 do
	    local angle = randAngle + angleInterval * x
	    local needleVector = {math.cos(angle), math.sin(angle)}

	    local position = mcontroller.position()
	    local visualConfig = {
	      power = 0,
	      timeToLive = self.visualProjectileTime,
	      speed = self.visualProjectileSpeed,
	      physics = "default"
	    }


	      world.spawnProjectile(self.visualProjectileType, position, entity.id(), needleVector, true, visualConfig)

	    self.spawnedThorns = self.spawnedThorns + 1
	  end
    end
end

function triggerThorns(damage)
  if self.visualProjectileType then
    self.triggerThorns = true
    self.thornDamage = damage
    self.thornsTimer = self.visualDuration
  end

  local damageConfig = {
    power = damage,
    speed = 0,
    physics = "default"
  }
  world.spawnProjectile(self.damageProjectileType, mcontroller.position(), entity.id(), {0, 0}, true, damageConfig)
end

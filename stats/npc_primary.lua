require "/scripts/kit/falldamagesettings.lua"

function init()
  --fall damage code
  self.lastYPosition = 0
  self.lastYVelocity = 0
  self.fallDistance = 0

  self.fallDamagePreferences = settings.stringToInteger[settings.getSetting("npcs", "aggressive")] or 0

  --end of fall damage code

  self.damageFlashTime = 0
  self.hitInvulnerabilityTime = 0

  self.worldBottomDeathLevel = 5

  message.setHandler("applyStatusEffect", function(_, _, effectConfig, duration, sourceEntityId)
      status.addEphemeralEffect(effectConfig, duration, sourceEntityId)
    end)
end

function applyDamageRequest(damageRequest)
  --modified next line
  if damageRequest.damageSourceKind ~= "falling" and (self.hitInvulnerabilityTime > 0 or self.hitInvulnerabilityTime > 0 or world.getProperty("nonCombat")) then
    return {}
  end

  local damage = 0
  if damageRequest.damageType == "Damage" or damageRequest.damageType == "Knockback" then
    damage = damage + root.evalFunction2("protection", damageRequest.damage, status.stat("protection"))
  elseif damageRequest.damageType == "IgnoresDef" then
    damage = damage + damageRequest.damage
  elseif damageRequest.damageType == "Environment" then
    return {}
  end

  if damageRequest.hitType == "ShieldHit" and status.statPositive("shieldHealth") and status.resourcePositive("shieldStamina") then
    status.modifyResource("shieldStamina", -damage / status.stat("shieldHealth"))
    status.setResourcePercentage("shieldStaminaRegenBlock", 1.0)
    damage = 0
    damageRequest.statusEffects = {}
    damageRequest.damageSourceKind = "shield"
  end

  local healthLost = math.min(damage, status.resource("health"))
  if healthLost > 0 and damageRequest.damageType ~= "Knockback" then
    status.modifyResource("health", -healthLost)
    self.damageFlashTime = 0.07
    if status.statusProperty("hitInvulnerability") then
      local damageHealthPercentage = healthLost / status.resourceMax("health")
      if damageHealthPercentage > status.statusProperty("hitInvulnerabilityThreshold") then
        self.hitInvulnerabilityTime = status.statusProperty("hitInvulnerabilityTime")
      end
    end
  end

  status.addEphemeralEffects(damageRequest.statusEffects, damageRequest.sourceEntityId)

  local knockbackFactor = (1 - status.stat("grit"))
  local momentum = knockbackMomentum(vec2.mul(damageRequest.knockbackMomentum, knockbackFactor))
  if status.resourcePositive("health") and vec2.mag(momentum) > 0 then
    mcontroller.setVelocity({0,0})
    if vec2.mag(momentum) > status.stat("knockbackThreshold") then
      mcontroller.addMomentum(momentum)
      status.setResource("stunned", math.max(status.resource("stunned"), status.stat("knockbackStunTime")))
    end
  end

  local hitType = damageRequest.hitType
  if not status.resourcePositive("health") then
    hitType = "kill"
  end
  return {{
    sourceEntityId = damageRequest.sourceEntityId,
    targetEntityId = entity.id(),
    position = mcontroller.position(),
    damageDealt = damage,
    healthLost = healthLost,
    hitType = hitType,
    kind = "Normal",
    damageSourceKind = damageRequest.damageSourceKind,
    targetMaterialKind = status.statusProperty("targetMaterialKind")
  }}
end

function notifyResourceConsumed(resourceName, amount)
  if resourceName == "energy" and amount > 0 then
    status.setResourcePercentage("energyRegenBlock", 1.0)
  end
end

function knockbackMomentum(momentum)
  local knockback = vec2.mag(momentum)
  if mcontroller.baseParameters().gravityEnabled and math.abs(momentum[1]) > 0  then
    local dir = momentum[1] > 0 and 1 or -1
    return {dir * knockback / 1.41, knockback / 1.41}
  else
    return momentum
  end
end

function update(dt)
  --fall damage
  if (self.fallDamagePreferences == 1 or (self.fallDamagePreferences == 2 and world.entityAggressive(entity.id()))) and mcontroller.baseParameters().gravityEnabled then
    local minimumFallDistance = 14
    local fallDistanceDamageFactor = 3
    local minimumFallVel = 40
    local baseGravity = 80
    local gravityDiffFactor = 1 / 30.0

    local curYPosition = mcontroller.yPosition()
    local yPosChange = curYPosition - (self.lastYPosition or curYPosition)

	if self.fallDistance > minimumFallDistance and -self.lastYVelocity > minimumFallVel and mcontroller.onGround() and not inLiquid() then
	  --fall damage is proportional to max health, with 100.0 being the player's standard
	  local healthRatio = status.stat("maxHealth") / 100.0

      local damage = (self.fallDistance - minimumFallDistance) * fallDistanceDamageFactor
      damage = damage * (1.0 + (world.gravity(mcontroller.position()) - baseGravity) * gravityDiffFactor)
      damage = damage * healthRatio
      status.applySelfDamageRequest({
          damageType = "IgnoresDef",
          damage = damage,
          damageSourceKind = "falling",
          sourceEntityId = entity.id()
        })
    end

	if mcontroller.yVelocity() < -minimumFallVel and not mcontroller.onGround() then
      self.fallDistance = self.fallDistance + -yPosChange
    else
      self.fallDistance = 0
    end

    self.lastYPosition = curYPosition
    self.lastYVelocity = mcontroller.yVelocity()
  end
  --end of fall damage

  if self.damageFlashTime > 0 then
    status.setPrimaryDirectives("fade=ff0000=0.85")
  else
    status.setPrimaryDirectives()
  end
  self.damageFlashTime = math.max(0, self.damageFlashTime - dt)

  if status.statusProperty("hitInvulnerability") then
    self.hitInvulnerabilityTime = math.max(self.hitInvulnerabilityTime - dt, 0)
    local flashTime = status.statusProperty("hitInvulnerabilityFlash")

    if self.hitInvulnerabilityTime > 0 then
      if math.fmod(self.hitInvulnerabilityTime, flashTime) > flashTime / 2 then
        status.setPrimaryDirectives(status.statusProperty("damageFlashOffDirectives"))
      else
        status.setPrimaryDirectives(status.statusProperty("damageFlashOnDirectives"))
      end
    else
      status.setPrimaryDirectives()
    end
  end

  if status.resource("energy") == 0 then
    status.setResourceLocked("energy", true)
  elseif status.resourcePercentage("energy") == 1 then
    status.setResourceLocked("energy", false)
  end

  if not status.resourcePositive("energyRegenBlock") then
    status.modifyResourcePercentage("energy", status.stat("energyRegenPercentageRate") * dt)
  end

  if not status.resourcePositive("shieldStaminaRegenBlock") then
    status.modifyResourcePercentage("shieldStamina", status.stat("shieldStaminaRegen") * dt)
  end

  if mcontroller.atWorldLimit(true) then
    status.setResourcePercentage("health", 0)
  end

  -- drawDebugResources()
end

function drawDebugResources()
  local position = mcontroller.position()

  local y = 2
  local resourceName = "energy"
  --Border
  world.debugLine(vec2.add(position, {-2, y+0.125}), vec2.add(position, {-2, y + 0.75}), "black")
  world.debugLine(vec2.add(position, {-2, y + 0.75}), vec2.add(position, {2, y + 0.75}), "black")
  world.debugLine(vec2.add(position, {2, y + 0.75}), vec2.add(position, {2, y+0.125}), "black")
  world.debugLine(vec2.add(position, {2, y+0.125}), vec2.add(position, {-2, y+0.125}), "black")

  local width = 3.75 * status.resource(resourceName) / status.resourceMax(resourceName)
  world.debugLine(vec2.add(position, {-1.875, y + 0.25}), vec2.add(position, {-1.875 + width, y + 0.25}), "green")
  world.debugLine(vec2.add(position, {-1.875, y + 0.375}), vec2.add(position, {-1.875 + width, y + 0.375}), "green")
  world.debugLine(vec2.add(position, {-1.875, y + 0.5}), vec2.add(position, {-1.875 + width, y + 0.5}), "green")
  world.debugLine(vec2.add(position, {-1.875, y + 0.625}), vec2.add(position, {-1.875 + width, y + 0.625}), "green")

  world.debugText(resourceName, vec2.add(position, {2.25, y - 0.125}), "blue")
  y = y + 1
end

function inLiquid() --no fall damage while submerged in liquids, Period.
	local excludeLiquidIds={49,50,62,63,64,66} --gases are not liquids.
	local liquidID = 0
	if mcontroller.liquidPercentage() > 0.1 then
		liquidID = mcontroller.liquidId()
    for i=1,excludeLiquidIds.n do
      if excludeLiquidIds[i] == liquidID then
				liquidID=0
        break
      end
    end
	end
	return liquidID > 0
end

require "/scripts/vec2.lua"
require "/scripts/kit/falldamagesettings.lua"

function init()
  --fall damage code
  self.lastYPosition = 0
  self.lastYVelocity = 0
  self.fallDistance = 0

  self.fallDamagePreferences = settings.stringToInteger[settings.getSetting("monsters", "all")] or 0

  --end of fall damage code

  self.damageFlashTime = 0

  self.worldBottomDeathLevel = 5

  message.setHandler("applyStatusEffect", function(_, _, effectConfig, duration, sourceEntityId)
      status.addEphemeralEffect(effectConfig, duration, sourceEntityId)
    end)
end

function applyDamageRequest(damageRequest)
  --modified next line
  if damageRequest.damageSourceKind ~= "falling" and world.getProperty("nonCombat") then
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

  if status.resourcePositive("shieldHealth") then
    local shieldAbsorb = math.min(damage, status.resource("shieldHealth"))
    status.modifyResource("shieldHealth", -shieldAbsorb)
    damage = damage - shieldAbsorb
  end

  local hitType = damageRequest.hitType
  
  
  local elementalStat = root.elementalResistance(damageRequest.damageSourceKind)
  local resistance = status.stat(elementalStat)
  damage = damage - (resistance * damage)
  if resistance ~= 0 and damage > 0 then
    hitType = resistance > 0 and "weakhit" or "stronghit"
  end

  local healthLost = math.min(damage, status.resource("health"))
  if healthLost > 0 and damageRequest.damageType ~= "Knockback" then
    status.modifyResource("health", -healthLost)
    if hitType == "stronghit" then
      self.damageFlashTime = 0.07		
      self.damageFlashType = "strong"		
    elseif hitType == "weakhit" then		
      self.damageFlashTime = 0.07		
      self.damageFlashType = "weak"		
    else		
      self.damageFlashTime = 0.07		
      self.damageFlashType = "default"		
    end 
  end

  status.addEphemeralEffects(damageRequest.statusEffects, damageRequest.sourceEntityId)

  local knockbackFactor = (1 - status.stat("grit"))
  local momentum = knockbackMomentum(vec2.mul(damageRequest.knockbackMomentum, knockbackFactor))
  if status.resourcePositive("health") and vec2.mag(momentum) > 0 then
    self.applyKnockback = momentum
    if vec2.mag(momentum) > status.stat("knockbackThreshold") then
      status.setResource("stunned", math.max(status.resource("stunned"), status.stat("knockbackStunTime")))
    end
  end


  if not status.resourcePositive("health") then
    hitType = "kill"
    --bows should cause hunting drops regardless of damageKind
    if string.find(elementalStat, "bow") then
      string.gsub(elementalStat, "fire", "")
      string.gsub(elementalStat, "ice", "")
      string.gsub(elementalStat, "electric", "")
      string.gsub(elementalStat, "poison", "")
      string.gsub(elementalStat, "shadow", "")
      string.gsub(elementalStat, "radioactive", "")
      string.gsub(elementalStat, "cosmic", "")
    end
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
    local color = status.statusProperty("damageFlashColor") or "ff0000=0.85"
    if self.damageFlashType == "strong" then		
      color = status.statusProperty("strongDamageFlashColor") or "ffffff=1.0" or color		
    elseif self.damageFlashType == "weak" then		
      color = status.statusProperty("weakDamageFlashColor") or "000000=0.0" or color		
    end    
    status.setPrimaryDirectives(string.format("fade=%s", color))
  else
    status.setPrimaryDirectives()
  end
  self.damageFlashTime = math.max(0, self.damageFlashTime - dt)

  if self.applyKnockback then
    mcontroller.setVelocity({0,0})
    if vec2.mag(self.applyKnockback) > status.stat("knockbackThreshold") then
      mcontroller.addMomentum(self.applyKnockback)
    end
    self.applyKnockback = nil
  end

  if mcontroller.atWorldLimit(true) then
    status.setResourcePercentage("health", 0)
  end
end

function inLiquid() --no fall damage while submerged in liquids
    local excludeLiquidIds={[49] = true,[50] = true,[62] = true,[63] = true,[64] = true,[66] = true} --gases are not liquids.
    local liquidID = 0
    if mcontroller.liquidPercentage() > 0.1 then
    liquidID = mcontroller.liquidId()
       liquidID = excludeLiquidIds[liquidID] and 0 or liquidID 
    end
    return liquidID > 0
end
require "/scripts/util.lua"
require "/scripts/status.lua"

function init()
  self.debug = tfalse
  if self.debug then sb.logInfo("(FR) shield.lua init() for %s", activeItem.hand()) end
  
  self.aimAngle = 0
  self.aimDirection = 1

  self.active = false
  self.cooldownTimer = config.getParameter("cooldownTime")
  self.activeTimer = 0

  self.level = config.getParameter("level", 1)
  self.baseShieldHealth = config.getParameter("baseShieldHealth", 1)
  self.knockback = config.getParameter("knockback", 0)
  self.perfectBlockDirectives = config.getParameter("perfectBlockDirectives", "")
  self.perfectBlockTime = config.getParameter("perfectBlockTime", 0.2)
  self.minActiveTime = config.getParameter("minActiveTime", 0)
  self.cooldownTime = config.getParameter("cooldownTime")
  self.forceWalk = config.getParameter("forceWalk", false)
  
  -- FU special effects
    -- health effects
	  self.shieldHealthRegen = config.getParameter("shieldHealthRegen", 1)
	  shieldEnergyRegen = config.getParameter("shieldEnergyRegen",0)
	  status.setPersistentEffects("shieldEnergyRegen", {{stat = "energyRegenPercentageRate", amount = shieldEnergyRegen}})
	  
	  shieldHealthBonus = config.getParameter("shieldHealthBonus",0)*(status.resourceMax("health"))
	  status.setPersistentEffects("shieldHealthBonus", {{stat = "maxHealth", amount = shieldHealthBonus}})
	  shieldEnergyBonus = config.getParameter("shieldEnergyBonus",0)*(status.resourceMax("energy"))
	  status.setPersistentEffects("shieldEnergyBonus", {{stat = "maxEnergy", amount = shieldEnergyBonus}})   
	  
    -- protections	  
	  shieldProtection = config.getParameter("shieldProtection",0)
	  status.setPersistentEffects("shieldProtection", {{stat = "protection", amount = shieldProtection}})

    -- encironmental protections
	  protectionBee = config.getParameter("protectionBee",0)
	  status.setPersistentEffects("protectionBee", {{stat = "beestingImmunity", amount = protectionBee}})	    
	  protectionAcid = config.getParameter("protectionAcid",0)
	  status.setPersistentEffects("protectionAcid", {{stat = "sulphuricImmunity", amount = protectionAcid}})
	  protectionBlackTar = config.getParameter("protectionBlackTar",0)
	  status.setPersistentEffects("protectionBlackTar", {{stat = "blacktarImmunity", amount = protectionBlackTar}})	  
	  protectionBioooze = config.getParameter("protectionBioooze",0)
	  status.setPersistentEffects("protectionBioooze", {{stat = "biooozeImmunity", amount = protectionBioooze}}) 
	  protectionPoison = config.getParameter("protectionPoison",0)
	  status.setPersistentEffects("protectionPoison", {{stat = "poisonStatusImmunity", amount = protectionPoison}}) 
	  protectionInsanity = config.getParameter("protectionInsanity",0)
	  status.setPersistentEffects("protectionInsanity", {{stat = "insanityImmunity", amount = protectionInsanity}})	  
	  protectionShock = config.getParameter("protectionShock",0)
	  status.setPersistentEffects("protectionShock", {{stat = "shockStatusImmunity", amount = protectionShock}})	 
	  protectionSlime = config.getParameter("protectionSlime",0)
	  status.setPersistentEffects("protectionSlime", {{stat = "slimeImmunity", amount = protectionSlime}})	 
	  protectionLava = config.getParameter("protectionLava",0)
	  status.setPersistentEffects("protectionLava", {{stat = "lavaImmunity", amount = protectionLava}}) 
	  protectionFire = config.getParameter("protectionFire",0)
	  status.setPersistentEffects("protectionFire", {{stat = "fireStatusImmunity", amount = protectionFire}}) 
	  protectionProto = config.getParameter("protectionProto",0)
	  status.setPersistentEffects("protectionProto", {{stat = "protoImmunity", amount = protectionProto}})	  
  	  	  
	  protectionCold = config.getParameter("protectionCold",0)
	  status.setPersistentEffects("protectionCold", {{stat = "biomecoldImmunity", amount = protectionCold}})
	  protectionXCold = config.getParameter("protectionXCold",0)
	  status.setPersistentEffects("protectionXCold", {{stat = "ffextremecoldImmunity", amount = protectionXCold}})	
	  
	  protectionHeat = config.getParameter("protectionHeat",0)
	  status.setPersistentEffects("protectionHeat", {{stat = "biomeheatImmunity", amount = protectionHeat}})
	  protectionXHeat = config.getParameter("protectionXHeat",0)
	  status.setPersistentEffects("protectionXHeat", {{stat = "ffextremeheatImmunity", amount = protectionXHeat}})	

	  protectionRads = config.getParameter("protectionRads",0)
	  status.setPersistentEffects("protectionRads", {{stat = "biomeradiationImmunity", amount = protectionRads}})
	  protectionXRads = config.getParameter("protectionXRads",0)
	  status.setPersistentEffects("protectionXRads", {{stat = "ffextremeradiationImmunity", amount = protectionXRads}})

  -- end FU special effects
  
  
  animator.setGlobalTag("directives", "")
  animator.setAnimationState("shield", "idle")
  activeItem.setOutsideOfHand(true)

  self.stances = config.getParameter("stances")
  setStance(self.stances.idle)

  updateAim()
end

function update(dt, fireMode, shiftHeld)
  self.cooldownTimer = math.max(0, self.cooldownTimer - dt)

  if not self.active
    and fireMode == "primary"
    and self.cooldownTimer == 0
    and status.resourcePositive("shieldStamina") then

    raiseShield()
  end

  if self.active then
    self.activeTimer = self.activeTimer + dt

    self.damageListener:update()

    --
    --
    --
    --
    -- FU SPECIALS
    status.modifyResourcePercentage("health", self.shieldHealthRegen * dt)
    status.modifyResourcePercentage("energy", self.shieldEnergyRegen * dt)
    --
    --
    --
    --
    --
    
    
    
    if status.resourcePositive("perfectBlock") then
      animator.setGlobalTag("directives", self.perfectBlockDirectives)
    else
      animator.setGlobalTag("directives", "")
    end

    if self.forceWalk then
      mcontroller.controlModifiers({runningSuppressed = true})
    end

    if (fireMode ~= "primary" and self.activeTimer >= self.minActiveTime) or not status.resourcePositive("shieldStamina") then
      lowerShield()
    end
  end

  updateAim()
end

function uninit()
  status.clearPersistentEffects(activeItem.hand().."Shield")
  activeItem.setItemShieldPolys({})
  activeItem.setItemDamageSources({})
  status.clearPersistentEffects("shieldHealthBonus")
  status.clearPersistentEffects("shieldEnergyBonus")
  status.clearPersistentEffects("shieldProtection")
  status.clearPersistentEffects("protectionBee")
  status.clearPersistentEffects("protectionAcid")
  status.clearPersistentEffects("protectionBlackTar")
  status.clearPersistentEffects("protectionBioooze")
  status.clearPersistentEffects("protectionPoison")  
  status.clearPersistentEffects("protectionLava")  
  status.clearPersistentEffects("protectionFire")  
  status.clearPersistentEffects("protectionShock")  
  status.clearPersistentEffects("protectionSlime")  
  status.clearPersistentEffects("protectionInsanity") 
  status.clearPersistentEffects("protectionCold")  
  status.clearPersistentEffects("protectionXCold")  
  status.clearPersistentEffects("protectionHeat")  
  status.clearPersistentEffects("protectionXHeat")  
  status.clearPersistentEffects("protectionRads")  
  status.clearPersistentEffects("protectionXRads")  
end

function updateAim()
  local aimAngle, aimDirection = activeItem.aimAngleAndDirection(0, activeItem.ownerAimPosition())
  
  if self.stance.allowRotate then
    self.aimAngle = aimAngle
  end
  activeItem.setArmAngle(self.aimAngle + self.relativeArmRotation)

  if self.stance.allowFlip then
    self.aimDirection = aimDirection
  end
  activeItem.setFacingDirection(self.aimDirection)

  animator.setGlobalTag("hand", isNearHand() and "near" or "far")
  activeItem.setOutsideOfHand(not self.active or isNearHand())
end

function isNearHand()
  return (activeItem.hand() == "primary") == (self.aimDirection < 0)
end

function setStance(stance)
  self.stance = stance
  self.relativeShieldRotation = util.toRadians(stance.shieldRotation) or 0
  self.relativeArmRotation = util.toRadians(stance.armRotation) or 0
end

function raiseShield()
  setStance(self.stances.raised)
  animator.setAnimationState("shield", "raised")
  animator.playSound("raiseShield")
  self.active = true
  self.activeTimer = 0
  status.setPersistentEffects(activeItem.hand().."Shield", {{stat = "shieldHealth", amount = shieldHealth()}})
  local shieldPoly = animator.partPoly("shield", "shieldPoly")
  activeItem.setItemShieldPolys({shieldPoly})

  if self.knockback > 0 then
    local knockbackDamageSource = {
      poly = shieldPoly,
      damage = 0,
      damageType = "Knockback",
      sourceEntity = activeItem.ownerEntityId(),
      team = activeItem.ownerTeam(),
      knockback = self.knockback,
      rayCheck = true,
      damageRepeatTimeout = 0.25
    }
    activeItem.setItemDamageSources({ knockbackDamageSource })
  end

  self.damageListener = damageListener("damageTaken", function(notifications)
    for _,notification in pairs(notifications) do
      if notification.hitType == "ShieldHit" then
        if status.resourcePositive("perfectBlock") then
          animator.playSound("perfectBlock")
          animator.burstParticleEmitter("perfectBlock")
          refreshPerfectBlock()
        elseif status.resourcePositive("shieldStamina") then
          animator.playSound("block")
        else
          animator.playSound("break")
        end
        animator.setAnimationState("shield", "block")
        return
      end
    end
  end)

  refreshPerfectBlock()
end

function refreshPerfectBlock()
  local perfectBlockTimeAdded = math.max(0, math.min(status.resource("perfectBlockLimit"), self.perfectBlockTime - status.resource("perfectBlock")))
  status.overConsumeResource("perfectBlockLimit", perfectBlockTimeAdded)
  status.modifyResource("perfectBlock", perfectBlockTimeAdded)
end

function lowerShield()
  setStance(self.stances.idle)
  animator.setGlobalTag("directives", "")
  animator.setAnimationState("shield", "idle")
  animator.playSound("lowerShield")
  self.active = false
  self.activeTimer = 0
  status.clearPersistentEffects(activeItem.hand().."Shield")
  activeItem.setItemShieldPolys({})
  activeItem.setItemDamageSources({})
  self.cooldownTimer = self.cooldownTime
end

function shieldHealth()
  return self.baseShieldHealth * root.evalFunction("shieldLevelMultiplier", self.level)
end

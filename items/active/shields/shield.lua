require "/scripts/util.lua"
require "/scripts/status.lua"

function init()
  self.debug = false
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
  
    animator.setGlobalTag("directives", "")
    animator.setAnimationState("shield", "idle")
    activeItem.setOutsideOfHand(true)
  
    self.stances = config.getParameter("stances")
    setStance(self.stances.idle)
    
    self.blockCountShield = 0
    species = world.entitySpecies(activeItem.ownerEntityId()) 
    
   -- FU special effects
     -- health effects
          self.critChance = config.getParameter("critChance", 0)
          self.critBonus = config.getParameter("critBonus", 0)
          self.shieldBonusShield = config.getParameter("shieldBonusShield", 0)  -- bonus shield HP
          self.shieldBonusRegen = config.getParameter("shieldBonusRegen", 0)  -- bonus shield regen time
 	  self.shieldHealthRegen = config.getParameter("shieldHealthRegen", 0)
 	  shieldEnergyRegen = config.getParameter("shieldEnergyRegen",0)
 	  shieldHealthBonus = config.getParameter("shieldHealthBonus",0)*(status.resourceMax("health"))
 	  shieldEnergyBonus = config.getParameter("shieldEnergyBonus",0)*(status.resourceMax("energy"))
 	  shieldProtection = config.getParameter("shieldProtection",0)
 	  shieldStamina = config.getParameter("shieldStamina",0)
 	  shieldFalling = config.getParameter("shieldFalling",0)
 	  protectionBee = config.getParameter("protectionBee",0)
 	  protectionAcid = config.getParameter("protectionAcid",0)
 	  protectionBlackTar = config.getParameter("protectionBlackTar",0)
 	  protectionBioooze = config.getParameter("protectionBioooze",0)
 	  protectionPoison = config.getParameter("protectionPoison",0)
 	  protectionInsanity = config.getParameter("protectionInsanity",0)
 	  protectionShock = config.getParameter("protectionShock",0)
 	  protectionSlime = config.getParameter("protectionSlime",0)
 	  protectionLava = config.getParameter("protectionLava",0)
 	  protectionFire = config.getParameter("protectionFire",0)
 	  protectionProto = config.getParameter("protectionProto",0)
 	  protectionAcid = config.getParameter("protectionAcid",0)
 	  protectionBlackTar = config.getParameter("protectionBlackTar",0)
 	  protectionBioooze = config.getParameter("protectionBioooze",0)
 	  protectionPoison = config.getParameter("protectionPoison",0)
 	  protectionInsanity = config.getParameter("protectionInsanity",0)
 	  protectionShock = config.getParameter("protectionShock",0)
 	  protectionSlime = config.getParameter("protectionSlime",0)
 	  protectionLava = config.getParameter("protectionLava",0)
 	  protectionFire = config.getParameter("protectionFire",0)
 	  protectionProto = config.getParameter("protectionProto",0)
 	  protectionCold = config.getParameter("protectionCold",0)
 	  protectionXCold = config.getParameter("protectionXCold",0)
 	  protectionHeat = config.getParameter("protectionHeat",0)
 	  protectionXHeat = config.getParameter("protectionXHeat",0)
 	  protectionRads = config.getParameter("protectionRads",0)
 	  protectionXRads = config.getParameter("protectionXRads",0)	  
 	  shieldBash = config.getParameter("shieldBash",0)
 	  shieldBashPush = config.getParameter("shieldBashPush",0)
 	  
 	  
 	  status.setPersistentEffects("shieldEffects", {
 	  {stat = "baseShieldHealth", amount = config.getParameter("shieldBonusShield", 0) },
 	  {stat = "energyRegenPercentageRate", amount = shieldEnergyRegen},
 	  {stat = "maxHealth", amount = shieldHealthBonus},
 	  {stat = "maxEnergy", amount = shieldEnergyBonus},
 	  {stat = "protection", amount = shieldProtection},
 	  {stat = "shieldStaminaRegen", amount = shieldStamina},
 	  {stat = "fallDamageMultiplier", amount = shieldFalling},
 	  {stat = "beestingImmunity", amount = protectionBee},
 	  {stat = "sulphuricImmunity", amount = protectionAcid},
 	  {stat = "blacktarImmunity", amount = protectionBlackTar},
 	  {stat = "biooozeImmunity", amount = protectionBioooze},
 	  {stat = "poisonStatusImmunity", amount = protectionPoison},
 	  {stat = "insanityImmunity", amount = protectionInsanity},
 	  {stat = "shockStatusImmunity", amount = protectionShock},
 	  {stat = "slimeImmunity", amount = protectionSlime},
 	  {stat = "lavaImmunity", amount = protectionLava},
 	  {stat = "fireStatusImmunity", amount = protectionFire},
 	  {stat = "protoImmunity", amount = protectionProto},
 	  {stat = "sulphuricImmunity", amount = protectionAcid},
 	  {stat = "blacktarImmunity", amount = protectionBlackTar},
 	  {stat = "biooozeImmunity", amount = protectionBioooze},
 	  {stat = "poisonStatusImmunity", amount = protectionPoison},
 	  {stat = "insanityImmunity", amount = protectionInsanity},
 	  {stat = "electricStatusImmunity", amount = protectionShock},
 	  {stat = "slimeImmunity", amount = protectionSlime},
 	  {stat = "lavaImmunity", amount = protectionLava},
 	  {stat = "biomecoldImmunity", amount = protectionCold},
 	  {stat = "ffextremecoldImmunity", amount = protectionXCold},
 	  {stat = "biomeheatImmunity", amount = protectionHeat},
 	  {stat = "ffextremeheatImmunity", amount = protectionXHeat},
 	  {stat = "biomeradiationImmunity", amount = protectionRads},
 	  {stat = "ffextremeradiationImmunity", amount = protectionXRads},
 	  {stat = "shieldBash", amount = shieldBash},
 	  {stat = "shieldBashPush", amount = shieldBashPush}
 	  })
  -- end FU special effects
  
  species = world.entitySpecies(activeItem.ownerEntityId())
  
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
  status.clearPersistentEffects("shieldEffects")  
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
-- *** set up shield bash values *** --
          self.randomBash = math.random(100) + config.getParameter("shieldBash",0) + status.stat("shieldBash",0)
	  if not status.resource("energy") then
	    self.energyval= 0
	  else     
	    self.energyval= (status.resource("energy") / status.stat("maxEnergy")) * 100
	  end 
-- end shieldbash Init	          
        if status.resourcePositive("perfectBlock") then
          if (self.energyval) >= 50 and (self.randomBash) >= 50 then -- Shield Bash when perfect blocking
	    bashEnemy()
          end            
          animator.playSound("perfectBlock")
          animator.burstParticleEmitter("perfectBlock")
          refreshPerfectBlock()
        elseif status.resourcePositive("shieldStamina") then   
          if (self.energyval) >= 50 and (self.randomBash) >= 100 then -- Shield Bash when perfect blocking
	    bashEnemy()
          end         
          animator.playSound("block")
        else
          animator.playSound("break")
          if (self.energyval) <= 20 and (self.randomBash) >= 50 or (self.randomBash) >= 100 then -- if tired, we could end up stunned!
	    status.addEphemeralEffect("stun",1)
          end               
        end
        animator.setAnimationState("shield", "block")
        return
      end
    end
  end)

  refreshPerfectBlock()
end

function bashEnemy()
  if not status.resource("energy") then 
    self.energyValue = 0 
  else
    self.energyValue = status.resource("energy",0)
  end

  -- apply bonus stun
  self.stunBonus = config.getParameter("shieldBash",0) + config.getParameter("shieldBashPush",0)
  self.stunValue = math.random(100) + self.stunBonus
  
  -- lets limit how much damage they can do
  self.damageLimit = (self.energyval/50) + (status.stat("health")/50) + math.rand(6)

  if status.resourcePositive("perfectBlock") then
  	if self.stunValue >=100 then
		self.pushBack = math.random(24) + config.getParameter("shieldBashPush",0) + status.stat("shieldBashPush",0) + 6
		params = { speed=20, power = self.damageLimit , damageKind = "default", knockback = self.pushBack } -- Shield Bash	
		params2 = { speed=20, power = 0 , damageKind = "default", knockback = 0 } -- Stun	
		world.spawnProjectile("fu_genericBlankProjectile",mcontroller.position(),activeItem.ownerEntityId(),{0,0},false,params)
		world.spawnProjectile("shieldBashStunProjectile",mcontroller.position(),activeItem.ownerEntityId(),{0,0},false,params2)
		status.modifyResource("energy", self.energyValue * -0.2 )  -- consume energy	
		animator.playSound("shieldBash")
		animator.burstParticleEmitter("shieldBashHit")  	
  	else
		self.pushBack = math.random(24) + config.getParameter("shieldBashPush",0) + status.stat("shieldBashPush",0) + 6
		params = { speed=20, power = self.damageLimit , damageKind = "default", knockback = self.pushBack } -- Shield Bash		      
		world.spawnProjectile("fu_genericBlankProjectile",mcontroller.position(),activeItem.ownerEntityId(),{0,0},false,params)
		status.modifyResource("energy", self.energyValue * -0.2 )  -- consume energy		
		animator.playSound("shieldBash")
		animator.burstParticleEmitter("shieldBashHit")  	
  	end

  else
		self.pushBack = math.random(20) + config.getParameter("shieldBashPush",0) + status.stat("shieldBashPush",0) + 2
		params = { speed=20, power = self.damageLimit , damageKind = "default", knockback = self.pushBack } -- Shield Bash		      
		world.spawnProjectile("fu_genericBlankProjectile",mcontroller.position(),activeItem.ownerEntityId(),{0,0},false,params)
		status.modifyResource("energy", self.energyValue * -0.2 )  -- consume energy
		animator.playSound("shieldBash")
		animator.burstParticleEmitter("shieldBashHit")  	
  end
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
  status.clearPersistentEffects("shieldBonus") 
end

function shieldHealth()
  return self.baseShieldHealth * root.evalFunction("shieldLevelMultiplier", self.level)
end

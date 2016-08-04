require "/scripts/util.lua"
require "/scripts/status.lua"

function init()
  self.debug = true

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
  
  self.blockCount = 0.01 
  updateAim()
end

function update(dt, fireMode, shiftHeld)            
  self.cooldownTimer = math.max(0, self.cooldownTimer - dt)

--**************************************
 if self.blockCount == nil then 
   self.blockCount = 0.01 
 end
--**************************************

  if not self.active
    and fireMode == "primary"
    and self.cooldownTimer == 0
    and status.resourcePositive("shieldStamina") then
    raiseShield()
  end

  if self.active then
    self.activeTimer = self.activeTimer + dt

    self.damageListener:update()

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

          -- *******************************************************
          self.blockCount = self.blockCount + 0.01
          -- *******************************************************
          -- FRACKIN UNIVERSE and FRACKIN RACES abilities start here
          -- *******************************************************
          -- *******************************************************
          -- *******************************************************
          
          if world.entitySpecies(activeItem.ownerEntityId()) == "glitch" then
            self.blockCount = self.blockCount + 0.03
            status.setPersistentEffects("glitchprotection", {{stat = "powerMultiplier", amount = self.blockCount}})  --glitch get a power bonus when perfectly blocking
            animator.burstParticleEmitter("bonusBlock3")
          end
          if world.entitySpecies(activeItem.ownerEntityId()) == "hylotl" then
            status.modifyResourcePercentage("health", 0.05 + self.blockCount )  --hylotl get a heal when they perfectly block
            animator.burstParticleEmitter("bonusBlock")
          end
          if world.entitySpecies(activeItem.ownerEntityId()) == "viera" then
            status.modifyResourcePercentage("energy", 0.07 + self.blockCount )  --viera get energy when they perfectly block
            animator.burstParticleEmitter("bonusBlock2")
          end         
          -- *******************************************************
          -- *******************************************************
          -- *******************************************************
          -- *******************************************************
          
          refreshPerfectBlock()
        elseif status.resourcePositive("shieldStamina") then
          animator.playSound("block")
          
          
          -- *******************************************************
          self.blockCount = self.blockCount +0.01
            if world.entitySpecies(activeItem.ownerEntityId()) == "glitch" then   --glitch dont stack more bonus if they miss blocking
              self.blockCount = 0  --reset bonus here
              status.clearPersistentEffects("glitchprotection")
            end
          -- *******************************************************    
          
          
        else
          animator.playSound("break")
          
          
          -- *******************************************************
          self.blockCount = 0  --reset the blockCount here 
            if world.entitySpecies(activeItem.ownerEntityId()) == "glitch" then   --glitch dont stack more bonus if they miss blocking
              self.blockCount = 0  --reset bonus here
              status.clearPersistentEffects("glitchprotection")
            end
          -- *******************************************************
          
          
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

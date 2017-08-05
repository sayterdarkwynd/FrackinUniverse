require "/tech/doubletap.lua"
require "/scripts/vec2.lua"

function init()
  self.energyCostPerSecond = config.getParameter("energyCostPerSecond")
  self.dashControlForce = config.getParameter("dashControlForce")
  self.dashSpeedModifier = config.getParameter("dashSpeedModifier")
  self.groundOnly = config.getParameter("groundOnly")
  self.stopAfterDash = config.getParameter("stopAfterDash")
 
  self.dash = false
  self.effectDelay = 0
  
  self.chargeAttack = config.getParameter("chargeAttack",0)
  self.chargeAttackPower = config.getParameter("chargeAttackPower",0)
  self.hasChargeBonus = config.getParameter("hasChargeBonus",0)
  self.isInvulnerable = config.getParameter("isInvulnerable",0)
  
  self.doubleTap = DoubleTap:new({"left", "right"}, config.getParameter("maximumDoubleTapTime"), function(dashKey)
      local direction = dashKey == "left" and -1 or 1
      if not self.dashDirection
          and groundValid()
          and mcontroller.facingDirection() == direction
          and not mcontroller.crouching()
          and not status.resourceLocked("energy")
          and not status.statPositive("activeMovementAbilities") then

        startDash(direction)
      end
    end)
end

function uninit()
  status.clearPersistentEffects("movementAbility")
end

function update(args)
  self.doubleTap:update(args.dt, args.moves)

  if self.dashDirection then
    if args.moves[self.dashDirection > 0 and "right" or "left"]
        and not dashBlocked() then

      if mcontroller.facingDirection() == self.dashDirection then
        if status.overConsumeResource("energy", self.energyCostPerSecond * args.dt) then
          mcontroller.controlModifiers({speedModifier = self.dashSpeedModifier})
          
          animator.setAnimationState("dashing", "on")
          animator.setParticleEmitterActive("dashParticles", true)
          
          -- charge attack!
	    if self.chargeAttack == 1 then
	      local configBombDrop = { power = self.chargeAttackPower }
	      world.spawnProjectile("dashProjectile", mcontroller.position(), entity.id(), {0, 0}, false, configBombDrop)
	    end          
          
          
        else
          endDash()
        end
      else
        animator.setAnimationState("dashing", "off")
        animator.setParticleEmitterActive("dashParticles", false)
      end
    else
      endDash()
    end
  end
end

function groundValid()
  return mcontroller.groundMovement() or not self.groundOnly
end

function dashBlocked()
  return mcontroller.velocity()[1] == 0
end

function startDash(direction)
  self.dash = true
  self.dashDirection = direction
  animator.setFlipped(self.dashDirection == -1)
  animator.setAnimationState("dashing", "on")
  animator.setParticleEmitterActive("dashParticles", true)

  status.addPersistentEffect("fadeSprint", "invulnerable", math.huge)

  generateSkillEffectEnd()
end

function endDash(direction)
  self.dash = false

  if self.stopAfterDash then
    local movementParams = mcontroller.baseParameters()
    local currentVelocity = mcontroller.velocity()
    if math.abs(currentVelocity[1]) > movementParams.runSpeed then
      mcontroller.setVelocity({movementParams.runSpeed * self.dashDirection, 0})
    end
    mcontroller.controlApproachXVelocity(self.dashDirection * movementParams.runSpeed, self.dashControlForce)
  end

  animator.setAnimationState("dashing", "off")
  animator.setParticleEmitterActive("dashParticles", false)

  self.dashDirection = nil

  status.clearPersistentEffects("fadeSprint")
end

function generateSkillEffectEnd()

    
    if status.resource("energy") >= 50 and (self.hasChargeBonus) == 1 then
      status.addEphemeralEffect("damagebonus3",2) 
      animator.playSound("chargebonus")
      status.consumeResource("energy", 50)
    end
    
    if (self.isInvulnerable) == 1 then
      status.addEphemeralEffect("invulnerable", 1)
    end
    
end
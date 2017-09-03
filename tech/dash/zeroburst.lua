require "/tech/doubletap.lua"

function init()
  self.airDashing = false
  self.dashDirection = 0
  self.dashTimer = 0
  self.dashCooldownTimer = 0
  self.rechargeEffectTimer = 0
  self.energyCost = 80
  self.dashControlForce = config.getParameter("dashControlForce")
  self.dashSpeed = config.getParameter("dashSpeed")
  self.dashYVel = config.getParameter("dashYVel")
  self.dashDuration = config.getParameter("dashDuration")
  self.dashCooldown = config.getParameter("dashCooldown")
  self.stopAfterDash = config.getParameter("stopAfterDash")
  self.rechargeDirectives = config.getParameter("rechargeDirectives", "?fade=CCCCFFFF=0.25")
  self.rechargeEffectTime = config.getParameter("rechargeEffectTime", 0.1)
  self.groundOnly = config.getParameter("groundOnly")
  self.runSpeedMultiplier = config.getParameter("runSpeedMultiplier")
  self.groundForceMultiplierMax = config.getParameter("groundForceMultiplierMax")
  self.groundForceMultiplierMin = config.getParameter("groundForceMultiplierMin")

  self.doubleTap = DoubleTap:new({"up"}, config.getParameter("maximumDoubleTapTime"), function(dashKey)
      if self.dashTimer == 0
          and self.dashCooldownTimer == 0
          and groundValid()
          and not mcontroller.crouching()
          and not status.statPositive("activeMovementAbilities") then

        startDash(dashKey == "up" and 0 or 0)
      end
    end)
    
  self.superJumpTimer = 0
  self.damageProjectileType = "burstjumpboom"
  self.damageMultiplier = 1.0
  self.cooldown = 5
  
end

function uninit()
  status.clearPersistentEffects("movementAbility")
  tech.setParentDirectives()
end


function update(args)
local superJumpTime = 0.01

  if self.dashCooldownTimer > 0 then
    self.dashCooldownTimer = math.max(0, self.dashCooldownTimer - args.dt)
    if self.dashCooldownTimer == 0 then
      self.rechargeEffectTimer = self.rechargeEffectTime
      tech.setParentDirectives(self.rechargeDirectives)
      animator.playSound("recharge")
    end
  end

  if self.rechargeEffectTimer > 0 then
    self.rechargeEffectTimer = math.max(0, self.rechargeEffectTimer - args.dt)
    if self.rechargeEffectTimer == 0 then
      tech.setParentDirectives()
    end
  end

  self.doubleTap:update(args.dt, args.moves)

  if self.dashTimer > 0 then
    local blastPower = { power = 3 + config.getParameter("chipCost",2)}
    world.spawnProjectile("dashProjectile", mcontroller.position(), entity.id(), {0, 0}, true, blastPower)  
    
    mcontroller.controlApproachVelocity({self.dashSpeed * self.dashDirection, self.dashYVel}, self.dashControlForce)
    mcontroller.controlMove(self.dashDirection, true)
    if self.airDashing then
      mcontroller.controlParameters({gravityEnabled = false})
    end
    mcontroller.controlModifiers({jumpingSuppressed = true})

    animator.setFlipped(mcontroller.facingDirection() == -1)    

    self.dashTimer = math.max(0, self.dashTimer - args.dt)
    if self.dashTimer == 0 then
      endDash()
    end
  elseif mcontroller.groundMovement() and not mcontroller.liquidMovement() and mcontroller.running() and not status.statPositive("activeMovementAbilities") then
	mcontroller.controlModifiers({speedModifier = self.runSpeedMultiplier})
	local params = mcontroller.baseParameters()
	local maxSpeed = params.runSpeed * self.runSpeedMultiplier
	params.groundForce = params.groundForce * ( math.abs(mcontroller.velocity()[1]) / maxSpeed * ( self.groundForceMultiplierMax - self.groundForceMultiplierMin ) + self.groundForceMultiplierMin )
	mcontroller.controlParameters(params)	
  end
end

function groundValid()
  return mcontroller.groundMovement() or not self.groundOnly
end

function startDash(direction)
-- ***energy cost
 if status.overConsumeResource("energy", self.energyCost) and groundValid() then 
   status.setResourcePercentage("energyRegenBlock", 5.0)
-- ***end energy cost

-- ***start jump
  self.dashDirection = direction
  self.dashTimer = self.dashDuration
  self.airDashing = not mcontroller.groundMovement()
  status.setPersistentEffects("movementAbility", {{stat = "activeMovementAbilities", amount = 1}})
  animator.playSound("startDash")
  animator.setAnimationState("dashing", "on")
  animator.setParticleEmitterActive("dashParticles", true)
  
-- ***end jump

-- ***spawn projectile
    local damageConfig = { power = (status.stat("maxEnergy")/5),speed = 0,physics = "default" } 
    status.addEphemeralEffects{{effect = "nofalldamage", duration = self.cooldown}}
    world.spawnProjectile(self.damageProjectileType, mcontroller.position(), entity.id(), {0, 0}, true, damageConfig)
-- ***end projectile
 end
end

function endDash()
  status.clearPersistentEffects("movementAbility")

  if self.stopAfterDash then
  	    animator.setAnimationState("dashing", "on")
    animator.setParticleEmitterActive("dashParticles", true)
    local movementParams = mcontroller.baseParameters()
    local currentVelocity = mcontroller.velocity()
    if math.abs(currentVelocity[1]) > movementParams.runSpeed then
      mcontroller.setVelocity({movementParams.runSpeed * self.dashDirection, 0})
    end
    mcontroller.controlApproachXVelocity(self.dashDirection * movementParams.runSpeed, self.dashControlForce)
  end

  self.dashCooldownTimer = self.dashCooldown

  animator.setAnimationState("dashing", "off")
  animator.setParticleEmitterActive("dashParticles", false)
end

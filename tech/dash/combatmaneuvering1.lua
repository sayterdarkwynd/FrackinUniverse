require "/tech/doubletap.lua"

function init()
  self.airDashing = false
  self.dashDirection = 0
  self.dashTimer = 0
  self.dashCooldownTimer = 0
  self.rechargeEffectTimer = 0
  self.dashControlForce = config.getParameter("dashControlForce")
  self.dashSpeed = config.getParameter("dashSpeed")
  self.dashDuration = config.getParameter("dashDuration")
  self.dashCooldown = config.getParameter("dashCooldown")
  self.groundOnly = config.getParameter("groundOnly")
  self.stopAfterDash = config.getParameter("stopAfterDash")
  self.rechargeDirectives = config.getParameter("rechargeDirectives", "?fade=CCCCFFFF=0.25")
  self.rechargeEffectTime = config.getParameter("rechargeEffectTime", 0.1)
  self.hasjumped = 1
  self.dashingParticleTimer = 0
  self.allowJump = config.getParameter("allowJump")

  self.doubleTap = DoubleTap:new({"left", "right"}, config.getParameter("maximumDoubleTapTime"), function(dashKey)
      if self.dashTimer == 0
          and self.dashCooldownTimer == 0
          and groundValid()
          and not mcontroller.crouching()
          and not status.statPositive("activeMovementAbilities") then

        startDash(dashKey == "left" and -1 or 1)
      end
    end)

  animator.setAnimationState("dashing", "off")
end

function uninit()
  status.clearPersistentEffects("movementAbility")
  tech.setParentDirectives()
end

function applyTechBonus()
  self.dashBonus = 1 + status.stat("dashtechBonus") -- apply bonus from certain items and armor
  self.dodgetechBonus = 0 + status.stat("dodgetechBonus") -- apply bonus to defense from items and armor
  self.dashControlForce = config.getParameter("dashControlForce") * self.dashBonus
  self.dashSpeed = config.getParameter("dashSpeed") * self.dashBonus
end

function update(args)
  applyTechBonus()
  if self.dashingParticleTimer > 0 then
    self.dashingParticleTimer = math.max(0, self.dashingParticleTimer - args.dt)
    animator.setParticleEmitterActive("dashParticles", true)
  else
    animator.setParticleEmitterActive("dashParticles", false)
  end

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
    self.hasjumped = 1
    mcontroller.controlApproachVelocity({self.dashSpeed * self.dashDirection, 0}, self.dashControlForce)
    mcontroller.controlMove(self.dashDirection, true)

    mcontroller.controlModifiers({jumpingSuppressed = false})

    if self.allowJump < 1 then
      mcontroller.controlModifiers({jumpingSuppressed = true})
    end

    if self.airDashing then
      mcontroller.setYVelocity(0)
    end

    if args.moves["jump"] then
      self.hasjumped = 0.75
      endDash()
    end

    animator.setFlipped(mcontroller.facingDirection() == -1)

    self.dashTimer = math.max(0, self.dashTimer - args.dt)

    if self.dashTimer == 0 then
      endDash()
    end
  end
end

function groundValid()
  return mcontroller.groundMovement() or not self.groundOnly
end

function startDash(direction)
  self.dashingParticleTimer = self.dashDuration
  self.dashDirection = direction
  self.dashTimer = self.dashDuration
  self.airDashing = not mcontroller.groundMovement()
  status.setPersistentEffects("movementAbility", {{stat = "activeMovementAbilities", amount = 1}})
  animator.playSound("startDash")
  animator.setAnimationState("dashing", "on")
  animator.setParticleEmitterActive("dashParticles", true)
  
  -- defense bonus is applied if the player has the relevant stat. Otherwise we apply the basic small boost granted by the default tech
  status.setPersistentEffects("dodgeDefenseBoost", {{stat = "protection", effectiveMultiplier = (1 + self.dodgetechBonus)}})
  if config.getParameter("dodgeboost") ~= nil then
    status.addEphemeralEffect(config.getParameter("dodgeboost"))
  end
  
end

function endDash()
  status.clearPersistentEffects("movementAbility")
  status.clearPersistentEffects("dodgeDefenseBoost")
  local currentVelocity = mcontroller.velocity()
  if self.stopAfterDash then
    local movementParams = mcontroller.baseParameters()
    if math.abs(currentVelocity[1]) > movementParams.runSpeed then
      mcontroller.setVelocity({movementParams.runSpeed * self.dashDirection, 0})
    end
    mcontroller.controlApproachXVelocity(self.dashDirection * movementParams.runSpeed, self.dashControlForce)
  end

  currentVelocity = mcontroller.velocity()
  mcontroller.setVelocity({currentVelocity[1]*self.hasjumped, currentVelocity[2]})

  self.dashCooldownTimer = self.dashCooldown
  animator.setAnimationState("dashing", "off")
end

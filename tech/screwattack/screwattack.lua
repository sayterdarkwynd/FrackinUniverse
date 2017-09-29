function init()

  self.armRotation = 0
  self.rotations = 3
  self.rotationTime = 0.15
  self.jumpDuration = 0.2
  self.jumpTimer = self.jumpDuration
  self.energyUsage = 25

  self.groundJump = false
  self.flipTime = self.rotations * self.rotationTime
  self.flipTimer = 0

  self.metroidSprite = config.getParameter("useMetroidSprite")
end

function reinit()
  self.jumpTimer = self.jumpDuration
  status.clearPersistentEffects("movementAbility")
  mcontroller.setRotation(0)
  self.flipTimer = 0
  self.groundJump = false
  tech.setToolUsageSuppressed(false)

  if self.metroidSprite then
    tech.setParentHidden(false)
    animator.setAnimationState("screwattack", "off")
  else
    tech.setParentState()
  end
end

function uninit()
  reinit()
end

function update(args)
  local jumpActivated = args.moves["jump"] and not self.lastJump
  self.lastJump = args.moves["jump"]

  if self.groundJump then
    if mcontroller.onGround() then
      reinit()
    else
      tech.setToolUsageSuppressed(true)
      if self.metroidSprite then
        tech.setParentHidden(true)
        animator.setAnimationState("screwattack", "on")
        if mcontroller.xVelocity() < 0 then
          animator.setFlipped(true)
        else
          animator.setFlipped(false)
        end
      else
        tech.setParentState("sit")
      end
      status.addEphemeralEffect("screwattackinvuln", 1)
      flip(args.dt)
    end 
  end

--sb.logInfo("xvel: %s", mcontroller.xVelocity())

  if jumpActivated then
    local yVel = mcontroller.yVelocity()

    if mcontroller.onGround() and not status.statPositive("activeMovementAbilities") and not mcontroller.liquidMovement() 
       and math.abs(mcontroller.xVelocity()) > 2 then
       self.groundJump = true
    else
      if canMultiJump() and self.groundJump and (yVel < 10 and yVel > -45) then
        doMultiJump()
      end
    end

  end

  --updateJumpModifier()

  -- if jumpActivated and canMultiJump() then
  --   doMultiJump()
  -- else
  --   if mcontroller.groundMovement() or mcontroller.liquidMovement() then
  --     refreshJumps()
  --   end
  -- end
end

function flip(dt)
  status.setPersistentEffects("movementAbility", {{stat = "activeMovementAbilities", amount = 1}})


 

  --if self.flipTimer < self.flipTime then
    self.flipTimer = self.flipTimer + dt

    --sb.logInfo("fliptimer: %s, fliptime: %s", self.flipTimer, self.flipTime)

    --mcontroller.controlParameters(self.flipMovementParameters)

    if self.jumpTimer > 0 then
      self.jumpTimer = self.jumpTimer - dt
      --mcontroller.setVelocity({self.jumpVelocity[1] * mcontroller.facingDirection(), self.jumpVelocity[2]})
    end

    mcontroller.setRotation(-math.pi * 2 * mcontroller.facingDirection() * (self.flipTimer / self.rotationTime))
    mcontroller.controlParameters({collisionPoly = { {-1.8, -1.8},  {1.8, -1.8}, {1.8, 1.8}, {-1.8, 1.8} }  })

    --coroutine.yield()
  --else
    --reinit()
  --end




end

function canMultiJump()
  return not mcontroller.jumping()
      and not mcontroller.canJump()
      and not mcontroller.liquidMovement()
      and self.groundJump
      and status.overConsumeResource("energy", self.energyUsage)
      --and not status.statPositive("activeMovementAbilities")
end

function doMultiJump()
  mcontroller.controlJump(true)
  mcontroller.setYVelocity(math.max(0, mcontroller.yVelocity()))
  --self.multiJumps = self.multiJumps - 1
  --animator.burstParticleEmitter("multiJumpParticles")
  --animator.playSound("multiJumpSound")
end
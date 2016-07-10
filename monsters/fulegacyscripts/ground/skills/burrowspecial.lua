burrowSpecial = {}

function burrowSpecial.enter()
  -- if hasTarget() and self.skillCooldownTimers["burrowSpecial"] <= 0 and self.onGround then
  --   if not isBlocked() then
  --     sb.logInfo("Can't burrow because NOT BLOCKED")
  --   elseif world.magnitude(self.toTarget) > config.getParameter("burrowSpecial.maxRange") then
  --     sb.logInfo("Can't burrow because TOO FAR (max)")
  --   elseif self.toTarget[2] > 5 or self.toTarget[2] < -5 then
  --     sb.logInfo("Can't burrow because TOO FAR (vertical)")
  --   elseif burrowSpecial.canJumpUp() then
  --     sb.logInfo("Can't burrow because CAN JUMP UP")
  --   elseif #world.collisionBlocksAlongLine(mcontroller.position(), world.entityPosition(self.target)) > config.getParameter("burrowSpecial.maxThickness") then
  --     sb.logInfo("Can't burrow because TOO THICKE")
  --   end
  -- end

  if not hasTarget()
      or self.skillCooldownTimers["burrowSpecial"] > 0
      or not self.onGround
      or not isBlocked()
      --or self.toTarget[2] > 5 or self.toTarget[2] < -5 --don't dig too directly into the ceiling or floor
      or world.magnitude(self.toTarget) > config.getParameter("burrowSpecial.maxRange")
      or burrowSpecial.canJumpUp() --don't dig through short cliffs
      or #world.collisionBlocksAlongLine(mcontroller.position(), world.entityPosition(self.target)) > config.getParameter("burrowSpecial.maxThickness")
    then
      if self.skillCooldownTimers["burrowSpecial"] <= 0 then self.skillCooldownTimers["burrowSpecial"] = 0.2 end --don't check again immediately
      return nil
  end

  return { digTimer = 0 }
end

function burrowSpecial.canJumpUp()
  local canJumpUp
  local bb = mcontroller.boundBox()
  local pos = mcontroller.position()

  -- world.debugLine(pos, {pos[1], pos[2] + jumpHeight() + bb[4]}, "#FF00FF")
  -- world.debugLine({pos[1], pos[2] + jumpHeight() + bb[2]}, monster.toAbsolutePosition({ bb[3] + 2, jumpHeight() + bb[2]}), "#FF00FF")

  local upLine = { pos, {pos[1], pos[2] + jumpHeight() + bb[4]} }
  if world.lineTileCollision(upLine[1], upLine[2]) then
    canJumpUp = false
  else
    local overLine = { {pos[1], pos[2] + jumpHeight() + bb[2]}, monster.toAbsolutePosition({ bb[3] + 2, jumpHeight() + bb[2]})  }
    canJumpUp = not world.lineTileCollision(overLine[1], overLine[2])
  end

  return canJumpUp
end

function burrowSpecial.enteringState(stateData)
  animator.setAnimationState("attack", "idle")

  monster.setActiveSkillName("burrowSpecial")
end

function burrowSpecial.update(dt, stateData)
  if not canContinueSkill() then return true end
  if willFall() then return true end

  local obstructed = isBlocked() or not entity.entityInSight(self.target)
  if not obstructed and world.magnitude(self.toTarget) < config.getParameter("burrowSpecial.minRange") then return true end

  stateData.digTimer = stateData.digTimer - dt

  faceTarget()
  if math.abs(self.toTarget[1]) > config.getParameter("burrowSpecial.minRange") then
    --approach
    moveX(self.toTarget[1], true)
  else
    --target is above or below... hmmm....
  end

  --run if we're moving
  if isBlocked() then
    animator.setAnimationState("movement", "idle")
  else
    animator.setAnimationState("movement", "run")
  end

  if obstructed then
    --dig
    if stateData.digTimer <= 0 then
      local pConfig = {
        speed = 5,
        timeToLive = 0.01,
        actionOnReap = {
          {
            action = "explosion",
            foregroundRadius = config.getParameter("burrowSpecial.digSize"),
            backgroundRadius = 0,
            explosiveDamageAmount = config.getParameter("burrowSpecial.digDamage")
          }
        }
      }

      local digPosition
      if self.toTarget[2] > 1.5 then
        digPosition = monster.toAbsolutePosition({1.75, 1.0})
      elseif self.toTarget[2] < -1.5 then
        digPosition = monster.toAbsolutePosition({1.75, 0.0})
      else
        digPosition = monster.toAbsolutePosition({1.75, -1.5})
      end


      world.spawnProjectile("invisibleprojectile", digPosition, entity.id(), {mcontroller.facingDirection(), 0}, false, pConfig)
      stateData.digTimer = config.getParameter("burrowSpecial.digTime")
    end

    --rotate head
    local timeFraction = stateData.digTimer / config.getParameter("burrowSpecial.digTime")
    local maxRotate = math.pi / 180 * 30
    animator.rotateGroup("projectileAim", timeFraction * 1.5 * maxRotate - maxRotate)
  end

  return false
end

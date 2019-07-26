pounceAction = {}

function pounceAction.enterWith(args)
  if not args.pounceTarget then return nil end

  --Make sure the target is valid
  if not world.entityExists(args.pounceTarget) then
   return nil 
  end

  return { 
    targetId = args.pounceTarget,
    followUpAction = args.followUpAction,
    approachTimer = 5,
    didPounce = false,
    direction = 1
  }
end

function pounceAction.enteringState(stateData)
end

function pounceAction.update(dt, stateData)
  if not world.entityExists(stateData.targetId) then
    return true
  end

  local targetPosition = world.entityPosition(stateData.targetId)
  local jumpSpeed = mcontroller.baseParameters().airJumpProfile.jumpSpeed
  local toTarget = world.distance(targetPosition, mcontroller.position())
  local jumpVector,canPounce = util.aimVector(toTarget, jumpSpeed, 1.5, true)

  --Pounce if we can
  if not stateData.didPounce and canPounce and mcontroller.onGround() and entity.entityInSight(stateData.targetId) then
    mcontroller.setVelocity(jumpVector)
    stateData.direction = util.toDirection(toTarget[1])
    stateData.didPounce = true
    mcontroller.controlFace(toTarget[1])

    return false
  end

  --Otherwise approach the ball until we can pounce
  if not stateData.didPounce then
    stateData.approachTimer = stateData.approachTimer - dt

    if not approachPoint(dt, targetPosition, 1, true) and stateData.approachTimer > 0 and not self.pathing.stuck then
      return false
    end
  end

  --While pouncing
  if stateData.didPounce then
    setMovementState(true)
    mcontroller.controlParameters({airFriction=0})

    local toTarget = world.distance(targetPosition, mcontroller.position())
    toTarget[2] = toTarget[2] + 1
    if toTarget[2] < 0 then
      mcontroller.controlDown()
    end

    --If we're on ground, finish the pounce
    if mcontroller.onGround() then

      local targetName = world.monsterType(stateData.targetId)

      --Monijir TODO : should use config values on monsters instead?

      local isToy = targetName:match('^toy') ~= nil

      if (targetName == "petball" or isToy) and world.magnitude(toTarget) < 1 then
        world.callScriptedEntity(stateData.targetId, "punt", stateData.direction)
        status.modifyResource("playful", -30)
      end
    else
      return false
    end
  end

  return true, config.getParameter("actionParams.play.cooldown", 10)
end

sleepAction = {
  cooldown = 10
}

function sleepAction.enterWith(args)

  if not args.sleepAction and not args.sleepTarget then return nil end

  if args.sleepAction and status.resourcePercentage("sleepy") < 1 then
    return nil
  end

  if args.sleepTarget and status.resource("sleepy") < config.getParameter("actions.sleep.minSleepy", 65) then
    return nil
  end

  return {
    targetId  = args.sleepTarget,
    sleepSpot = args.sleepSpot,
    sleepAnimation = args.sleepAnimation,
    sleepRate = -5,
    sleeping  = false,
    petFloat  = false  }
end

function sleepAction.enteringState(stateData)
  if stateData.targetId then
    emote("sleepy")
  else
    animator.setParticleEmitterActive("sleep", true)
  end
end

function sleepAction.update(dt, stateData)
  if not stateData.sleeping then
    if not stateData.targetId then
      stateData.sleeping = true
      animator.setParticleEmitterActive("sleep", true)
    else
      if not world.entityExists(stateData.targetId) then return true end
      --Approach the target
      --Target modified by sleep position horizontally only to avoid pathfinding issues
      --0.125 * 1 box = 1 pixel
      local targetPosition = world.entityPosition(stateData.targetId)
      targetPosition = 
        {targetPosition[1] + (0.125 * stateData.sleepSpot[1]),
         targetPosition[2]}
      
      if not approachPoint(dt, targetPosition, 1.5, false) then
        if self.pathing.stuck then
          return true, entity.configParameter("actionParams.sleep.cooldown")
        end
        return false
      end
      --X offset was all ready applied for the path destination so only need y offset now
      targetPosition = 
        {targetPosition[1], 
        targetPosition[2] + (0.125 * stateData.sleepSpot[2])}
      stateData.petFloat = targetPosition
      stateData.sleeping = true
      animator.setParticleEmitterActive("sleep", true)
    end
  else
    status.modifyResource("sleepy", stateData.sleepRate * dt)
    if stateData.targetId then
      if not world.entityExists(stateData.targetId) then
        return true, config.getParameter("actionParams.sleep.cooldown", 15)
      end

      local sleepAnimation = stateData.sleepAnimation or "invisible"
      

      animator.setAnimationState("movement", sleepAnimation)
      
      sleepAction.float(stateData)
    
    else
      animator.setAnimationState("movement", "sleep")
    end

    if status.resourcePercentage("sleepy") <= 0 then 
      return true, config.getParameter("actionParams.sleep.cooldown", 15)
    else
      return false
    end
  end
end

function sleepAction.leavingState(stateData)
  setIdleState()
  animator.setParticleEmitterActive("sleep", false)
end

function sleepAction.float(stateData)
  mcontroller.setPosition(stateData.petFloat)
  mcontroller.controlParameters({gravityMultiplier=0})
  mcontroller.setXVelocity(0,100)
  mcontroller.setYVelocity(0,100)
end
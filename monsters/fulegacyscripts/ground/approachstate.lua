approachState = {}

function approachState.enter()
  if self.noOptionCount > 5 or not hasTarget() then return nil end

  return {
    pather = PathMover:new()
  }
end

function approachState.enteringState(stateData)
  stateData.prepTimer = entity.configParameter("approachTime", 4.0)
  stateData.lastDirection = mcontroller.facingDirection()

  entity.setAnimationState("movement", "run")
  entity.setAnimationState("attack", "idle")
end

function approachState.update(dt, stateData)
  if not hasTarget() then return true end

  stateData.prepTimer = stateData.prepTimer - dt
  if stateData.prepTimer <= 0 then
    self.state.pickState({flee=true})
    return true
  end

  if #self.skillOptions > 0 then
    local option = self.skillOptions[1]

    if pointWithinRect(mcontroller.position(), option.startRect) then
      --just stand around and wait, I guess...
      entity.setAnimationState("movement", "idle")
      faceTarget()
      return true
    else
      --TODO: how to handle separation movement?
      if option.valid then
        local deltaX
        stateData.pather.options.run = option.approachDistance >= 1.0
        local moved = stateData.pather:move(option.approachPoint, dt)
        deltaX = stateData.pather.deltaX

        -- If that still fails, fall back to very basic movement
        if moved == false or moved == "pathfinding" then
          move(option.approachDelta, option.approachDistance >= 1.0)
          deltaX = util.toDirection(option.approachDelta[1])

          --If pathing is stuck and fallback movement is stuck, flee
          if self.pathing.stuck and checkStuck() > 4 then
            self.state.pickState({flee=true})
            return true
          end
        elseif moved == "running" then
          --One of the pathing functions returned a running status
          setMovementState(option.approachDistance >= 1.0)
        elseif moved == true then
          --Arrived at the approachPoint somehow
          return true
        end

      elseif math.abs(option.approachDelta[1]) > 1 then
        move(option.approachDelta, true, 0)
      end

      if (math.abs(option.approachDelta[1]) < 5.5 and math.abs(self.toTarget[1]) < 6 and math.abs(option.approachDelta[2]) < 1) then
        mcontroller.controlFace(util.toDirection(self.toTarget[1]))
      else
        mcontroller.controlFace(deltaX)
      end
    end
  end

  return false
end

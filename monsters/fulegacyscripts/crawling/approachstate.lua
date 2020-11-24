approachState = {}

function approachState.enter()
  if self.noOptionCount > 5 or not hasTarget() then return nil end

  return {}
end

function approachState.enteringState(stateData)
  stateData.prepTimer = 2.0
  animator.setAnimationState("movement", "run")
  animator.setAnimationState("attack", "idle")
end

function approachState.update(dt, stateData)
  if not hasTarget() then return true end

  stateData.prepTimer = stateData.prepTimer - dt
  if stateData.prepTimer <= 0 then
    return true
  end

  if #self.skillOptions > 0 then
    local option = self.skillOptions[1]

    if pointWithinRect(mcontroller.position(), option.startRect) then
      --just stand around and wait, I guess...
      animator.setAnimationState("movement", "idle")
      faceTarget()
      return true
    else
      if checkStuck() > 4 then
        self.state.pickState({flee=true})
        return true
      end

      animator.setAnimationState("movement", "run")

      --TODO: how to handle separation movement?
      move(option.approachDelta, option.approachDistance >= 1.0, 0.2)
      if (math.abs(option.approachDelta[1]) < 5.5 and math.abs(self.toTarget[1]) < 6) then
        faceTarget()
      end
    end
  end

  return false
end
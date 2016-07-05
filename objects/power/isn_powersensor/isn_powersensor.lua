function update(dt)
  ---world.logInfo("POWER SENSOR RUN DEBUG aka PSRD")
  local powerLevel = isn_getCurrentPowerInput(false)
  ---world.logInfo("PSRD: powerLevel is " .. powerLevel)

  if not powerLevel then
    animator.setAnimationState("num", "invalid")
  elseif powerLevel <= 19 then
    animator.setAnimationState("num", tostring(math.floor(powerLevel)))
  elseif powerLevel > 19 then
    animator.setAnimationState("num", "excess")
  end
  ---world.logInfo("POWER SENSOR RUN DEBUG END")
end
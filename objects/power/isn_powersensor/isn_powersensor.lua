function update(dt)
  ---world.logInfo("POWER SENSOR RUN DEBUG aka PSRD")
  local powerLevel = isn_getCurrentPowerInput(false)
  ---world.logInfo("PSRD: powerLevel is " .. powerLevel)

  if not powerLevel then
    entity.setAnimationState("num", "invalid")
  elseif powerLevel <= 19 then
    entity.setAnimationState("num", tostring(math.floor(powerLevel)))
  elseif powerLevel > 19 then
    entity.setAnimationState("num", "excess")
  end
  ---world.logInfo("POWER SENSOR RUN DEBUG END")
end
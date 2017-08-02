require'/scripts/power.lua'

function update(dt)
  ---sb.logInfo("POWER SENSOR RUN DEBUG aka PSRD")
  local powerLevel = power.getTotalEnergy()
  ---sb.logInfo("PSRD: powerLevel is " .. powerLevel)

  if not powerLevel then
    animator.setAnimationState("num", "invalid")
  elseif powerLevel <= 128 then
    animator.setAnimationState("num", tostring(math.floor(powerLevel)))
  elseif powerLevel > 128 then
    animator.setAnimationState("num", "excess")
  end
  power.update(dt)
  ---sb.logInfo("POWER SENSOR RUN DEBUG END")
end
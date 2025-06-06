require'/scripts/fupower.lua'

function update(dt)
  ---sb.logInfo("POWER SENSOR RUN DEBUG aka PSRD")
  local powerLevel = power.getTotalEnergy(true)
  ---sb.logInfo("PSRD: powerLevel is " .. powerLevel)

  if not powerLevel then
    animator.setAnimationState("num", "invalid")
  elseif powerLevel <= 19 then
    animator.setAnimationState("num", tostring(math.floor(powerLevel)))
  elseif powerLevel > 19 then
    animator.setAnimationState("num", "excess")
  end
  power.update(dt)
  ---sb.logInfo("POWER SENSOR RUN DEBUG END")
end

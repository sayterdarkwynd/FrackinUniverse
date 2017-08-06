require'/scripts/power.lua'

function update(dt)
  ---sb.logInfo("POWER SENSOR RUN DEBUG aka PSRD")
  local powerLevel = tostring(math.floor(power.getTotalEnergy()))
  ---sb.logInfo("PSRD: powerLevel is " .. powerLevel)
  if #powerLevel < 3 then
    powerLevel = string.rep('0',3-#powerLevel)..powerLevel
  end
  if not tonumber(powerLevel) then
    animator.setAnimationState("one", "invalid")
	animator.setAnimationState("ten", "invalid")
	animator.setAnimationState("hundred", "invalid")
  elseif tonumber(powerLevel) <= 999 then
    animator.setAnimationState("one", string.sub(powerLevel,-1))
	animator.setAnimationState("ten", string.sub(powerLevel,-2,-2))
	animator.setAnimationState("hundred", string.sub(powerLevel,-3,-3))
  else
    animator.setAnimationState("one", "excess")
	animator.setAnimationState("ten", "excess")
	animator.setAnimationState("hundred", "excess")
  end
  power.update(dt)
  ---sb.logInfo("POWER SENSOR RUN DEBUG END")
end
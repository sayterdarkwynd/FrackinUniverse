require'/scripts/fupower.lua'

function update(dt)
	---sb.logInfo("POWER SENSOR RUN DEBUG aka PSRD")
	local powerLevel = tostring(math.floor(power.getTotalEnergyNoBattery()))
	--sb.logInfo("PSRD: powerLevel is " .. powerLevel)
	if #powerLevel < 4 then
		powerLevel = string.rep('0',4-#powerLevel)..powerLevel
	end
	if not tonumber(powerLevel) then
		animator.setAnimationState("one", "invalid")
		animator.setAnimationState("ten", "invalid")
		animator.setAnimationState("hundred", "invalid")
                animator.setAnimationState("thousand", "invalid")
	elseif tonumber(powerLevel) <= 9999 then
		animator.setAnimationState("one", string.sub(powerLevel,-1))
		animator.setAnimationState("ten", string.sub(powerLevel,-2,-2))
		animator.setAnimationState("hundred", string.sub(powerLevel,-3,-3))
                animator.setAnimationState("thousand", string.sub(powerLevel,-4,-4))
	else
		animator.setAnimationState("one", "excess")
		animator.setAnimationState("ten", "excess")
		animator.setAnimationState("hundred", "excess")
                animator.setAnimationState("thousand", "excess")
	end
	power.update(dt)
	---sb.logInfo("POWER SENSOR RUN DEBUG END")
end
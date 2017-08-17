function init()
	chicken()
end

function update(dt)
	if not deltaTime or deltaTime > 1 then
		chicken()
		deltaTime=0
	else
		deltaTime=deltaTime+dt
	end
end

function chicken()
	local windLevel = math.min(math.abs(world.windLevel(object.position())),12)

	if windLevel > 6 then
		animator.setAnimationState("base", "fast")
	elseif windLevel > 3 then
		animator.setAnimationState("base", "med")
	elseif windLevel > 0 then
		animator.setAnimationState("base", "slow")
	else
		animator.setAnimationState("base", "off")
	end
	
	return windLevel
end
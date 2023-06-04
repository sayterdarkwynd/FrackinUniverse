idleState = {}

function idleState.enter()
	if hasTarget() then return nil end
		animator.playSound("idleBreath")
	return {}
end

function idleState.update(dt, stateData)

end
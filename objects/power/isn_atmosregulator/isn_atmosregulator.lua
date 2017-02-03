function init()
	
end

function update(dt)
	if isn_hasRequiredPower() == false then
		animator.setAnimationState("switchState", "off")
		return
	end
	animator.setAnimationState("switchState", "on")
	
	isn_projectileAllInRange("isn_atmosprojectile",500)
end
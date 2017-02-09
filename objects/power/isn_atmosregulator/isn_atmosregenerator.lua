function init()
	
end

function update(dt)
	if isn_hasRequiredPower() == false then
		animator.setAnimationState("switchState", "off")
		return
	end
	animator.setAnimationState("switchState", "on")
	isn_effectAllInRange("isn_atmosregen",500)
	--isn_projectileAllInRange("isn_atmosregen",500)
end
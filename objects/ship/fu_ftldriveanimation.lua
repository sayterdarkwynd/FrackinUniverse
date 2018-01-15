function update()
	if world.flyingType() == "warp" then
		if animator.animationState("base") == "off" then
			animator.setAnimationState("base", "powerup")
		end
	else
		if animator.animationState("base") == "powered" then
			animator.setAnimationState("base", "powerdown")
		end
	end
end
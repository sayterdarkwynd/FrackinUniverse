
function update()
	localAnimator.clearDrawables()
	local detectConfig = animationConfig.animationParameter("pingDetectConfig")
	if (not detectConfig) or (not detectConfig.maxRange) then return end
	for _,id in pairs(world.objectQuery(activeItemAnimation.ownerPosition(),detectConfig.maxRange)) do
		--if world.containerSize(id) and world.containerSize(id) > 0 then
			localAnimator.addDrawable(
				{
					image = detectConfig.image,
					fullbright = true,
					position = world.entityPosition(id),
					centered = false,
					color = {255,255,255}
				},
				"overlay"
			)
		--end
	end
end

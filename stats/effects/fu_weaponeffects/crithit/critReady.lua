function init()
	activateVisualEffects()
end

function activateVisualEffects()
	if not (world.isMonster(entity.id()) or world.isNpc(entity.id())) then
		if (status.stat("isCharged") == 1) then
			  local statusTextRegion = { 0, 1, 0, 1 }
			  animator.setParticleEmitterOffsetRegion("critText", statusTextRegion)
			  animator.burstParticleEmitter("critText")
			  animator.playSound("burn")
			  --effect.setParentDirectives("fade=008800=0.2")
		end
	end
end


function update(dt)

end

function uninit()
end

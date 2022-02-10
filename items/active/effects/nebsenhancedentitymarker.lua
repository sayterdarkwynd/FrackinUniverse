require "/scripts/util.lua"

function update()
  localAnimator.clearDrawables()
  localAnimator.clearLightSources()

  local entityMarker = animationConfig.animationParameter("entityMarker")

  local markerImage = entityMarker.markerImage

  if markerImage then
    local entities = animationConfig.animationParameter("entities") or {}
    entities = util.filter(entities, world.entityExists)
    for _,entityId in pairs(entities) do
      local markerDrawable = {
        image = markerImage,
        centered = true,
        position = world.entityMouthPosition(entityId),
        fullbright = entityMarker.fullbright or false
      }
      localAnimator.addDrawable(markerDrawable, "overlay")

	  if entityMarker.markerLighting then
		local markerLighting = {
		  position = world.entityPosition(entityId),
		  color = entityMarker.markerLighting.lightColor,
		  pointLight = entityMarker.markerLighting.pointLight or 1,
		  pointBeam = entityMarker.markerLighting.pointBeam or 1,
		  beamAngle = entityMarker.markerLighting.beamAngle or 1,
		  beamAmbience = entityMarker.markerLighting.beamAmbience or 1
		}
		localAnimator.addLightSource(markerLighting)
	  end

	  if entityMarker.particles then
		if not self.particleTimer then
		  self.particleTimer = 0
		end
		self.particleTimer = self.particleTimer
		if self.particleTimer >= entityMarker.particles.particleTimer then
		  if entityMarker.particles.particleLoop then
			self.particleTimer = 0
		  end

		  localAnimator.spawnParticle(entityMarker.particles.particleOnMark)
		end
	  end

	  if entityMarker.markerAudio then
		localAnimator.playAudio(entityMarker.markerAudio.markerSound, entityMarker.markerAudio.soundLoopCount or 1, entityMarker.markerAudio.volume or 1.0)
	  end
    end
  end
end

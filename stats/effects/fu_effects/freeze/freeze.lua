require "/stats/effects/fu_statusUtil.lua"

function init()
	if (status.stat("iceResistance")>=config.getParameter("resistanceThreshold",0.75)) then
		effect.expire()
		return
	end
	if config.getParameter("isFreeze",0)==1 then
		animator.setParticleEmitterOffsetRegion("snow", mcontroller.boundBox())
		animator.setParticleEmitterActive("snow", true)
		effect.setParentDirectives("fade=DDDDFF=0.5")
	end

	legacyStun("freeze")
	didInit=true
end

function update(dt)
	if not didInit then return end
	--sb.logInfo("%s",status.stat("iceResistance"))
	mcontroller.controlModifiers({movementSuppressed = true})
end

function uninit()
	if didInit then
		legacyStun("freeze")
	end
end

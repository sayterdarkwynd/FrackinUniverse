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

	local stuns = status.statusProperty("stuns", {})
	stuns["freeze"] = true
	status.setStatusProperty("stuns", stuns)
	didInit=true
end

function update(dt)
	if not didInit then return end
	--sb.logInfo("%s",status.stat("iceResistance"))
	mcontroller.controlModifiers({movementSuppressed = true})
end

function uninit()
	if didInit then
		local stuns = status.statusProperty("stuns", {})
		stuns["freeze"] = nil
		status.setStatusProperty("stuns", stuns)
	end
end
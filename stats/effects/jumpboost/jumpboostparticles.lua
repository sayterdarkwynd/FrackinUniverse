function init()
	local bounds = mcontroller.boundBox()
	animator.setParticleEmitterOffsetRegion("jumpparticles", {bounds[1], bounds[2] + 0.2, bounds[3], bounds[2] + 0.3})
end

function update(dt)
	animator.setParticleEmitterActive("jumpparticles", config.getParameter("particles", true) and mcontroller.jumping())
end
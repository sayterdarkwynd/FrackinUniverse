function init()
	script.setUpdateDelta(5)
	if not world.entitySpecies(entity.id()) then return end
	animator.setParticleEmitterOffsetRegion("healing", mcontroller.boundBox())
	animator.setParticleEmitterEmissionRate("healing", config.getParameter("emissionRate", 3))
	animator.setParticleEmitterActive("healing", true)

	-- self.frEnabled=status.statusProperty("fr_enabled")
	-- self.species = status.statusProperty("fr_race") or world.entitySpecies(entity.id())
	self.didInit=true
end

function update(dt)
	if not self.didInit then init() end
	if status.statPositive("fuDirtBeer") then
		status.addEphemeralEffect("booze3", 240, entity.id())
		status.addEphemeralEffect("slow", 240, entity.id())
		status.addEphemeralEffect("maxhealthboostneg20", 240, entity.id())
	end
end

function uninit()

end

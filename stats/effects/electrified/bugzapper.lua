require "/scripts/util.lua"

function init()
	if isBug() then
		animator.setParticleEmitterOffsetRegion("sparks", mcontroller.boundBox())
		animator.setParticleEmitterActive("sparks", true)
		effect.setParentDirectives("fade=7733AA=0.25")
		script.setUpdateDelta(5)
		self.tickTime = config.getParameter("boltInterval", 1.0)
		self.tickTimer = self.tickTime
	end
end

function update(dt)
	if isBug() then
		self.tickTimer = self.tickTimer - dt
		if self.tickTimer <= 0 then
			self.tickTimer = self.tickTime
			zap()
		end
	end
end

function zap()
	world.spawnProjectile("bugzap", entity.position(), entity.id(),{0,0})
end

function isBug()
	if not world.isMonster(entity.id()) then return false end
	local checkbug=(not not contains(world.callScriptedEntity(entity.id(),"config.getParameter","scripts") or {},"/monsters/bugs/bug.lua"))
	local checkbee=(world.callScriptedEntity(entity.id(),"getClass") == 'bee')
	return checkbug or checkbee
end
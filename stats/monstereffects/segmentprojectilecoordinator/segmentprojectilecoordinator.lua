--TODO add position offsetting, 
require "/scripts/vec2.lua"

function init()
	
	local coordinator   = status.statusProperty('coordinator')
	local segmentNumber = coordinator.segmentNumber
	local totalSegments = coordinator.totalSegments
	local level 		= coordinator.level

	self.projectile 		= config.getParameter('projectile')
	self.pulse 				= config.getParameter('pulse')
	self.power 				= config.getParameter("power",10) * level
	if config.getParameter('reverse') then
		self.timer 			= (totalSegments - segmentNumber) / totalSegments * config.getParameter("pulse")
	else
		self.timer 			= segmentNumber / totalSegments * config.getParameter("pulse")
	end
end

function update(dt)

	if self.timer < 0 then

  		world.spawnProjectile(config.getParameter("projectile"), mcontroller.position(), entity.id(), mcontroller.velocity(), self.track, {power = self.power})

		self.timer = self.pulse

	end

	self.timer = self.timer - dt

	effect.modifyDuration(1)

end

function uninit()
end

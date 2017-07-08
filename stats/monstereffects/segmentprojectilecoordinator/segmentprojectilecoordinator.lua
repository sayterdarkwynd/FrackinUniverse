--TODO add position offsetting, 
require "/scripts/vec2.lua"
require "/scripts/util.lua"

function init()
	
	local coordinator   = status.statusProperty('coordinator')
	local segmentNumber = coordinator.segmentNumber
	local totalSegments = coordinator.totalSegments
	local level 		= coordinator.level


	self.projectile 		= config.getParameter('projectile')
	self.pulse 				= config.getParameter('pulse',1)
	self.mode				= config.getParameter('mode','velocity')
	self.track				= config.getParameter('track',false)
	self.vector				= config.getParameter('vector',{0,0})

	self.power 				= config.getParameter("power",10) * level

	if config.getParameter('reverse') then
		self.timer 			= (totalSegments - segmentNumber) / totalSegments * config.getParameter("pulse")
	else
		self.timer 			= segmentNumber / totalSegments * config.getParameter("pulse")
	end
end

function update(dt)

	if self.timer < 0 then

		if self.mode == 'velocity' then 

  			world.spawnProjectile(self.projectile, mcontroller.position(), entity.id(), mcontroller.velocity(), self.track, {power = self.power})

  		elseif self.mode == 'absolute' then

			world.spawnProjectile(self.projectile, mcontroller.position(), entity.id(), self.vector, self.track, {power = self.power})

		elseif self.mode == 'targeted' then

			if not self.target then
				self.target = util.closestValidTarget(20)
			elseif self.target == 0 then
				self.target = util.closestValidTarget(20)
			end
			
			if world.entityExists(self.target) and entity.entityInSight(target) then

				local vector = vec2.sub(world.entityPosition(target), mcontroller.position())
				
				world.spawnProjectile(self.projectile, mcontroller.position(), entity.id(), vector, self.track, {power = self.power})

			end

		end

		self.timer = self.pulse

	end

	self.timer = self.timer - dt

	effect.modifyDuration(1)

end

function uninit()
end

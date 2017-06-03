require "/scripts/vec2.lua"
require "/scripts/actions/animator.lua"

local monsterUpdate = update

function playerModified(position,range)
	return world.isPlayerModified({position[1]-range,position[2]-range,position[1]+range,position[2]+range})
end

function burrowEffect(dt)

    self.burrowing = world.polyCollision(self.burrowPoly, mcontroller.position(), {"block"})
    if not self.burrowed == self.burrowing then
    	if not playerModified(mcontroller.position(),2) then
			world.spawnProjectile(self.burrowBurstProjectile, mcontroller.position())
    	end
    	animator.burstParticleEmitter("groundBurstEmitter")
    	animator.setParticleEmitterActive("behindGroundEmitter", self.burrowing)
  		animator.setGlobalTag("groundState", self.burrowing and "below" or "above" )
    else  
	self.burrowTick = self.burrowTick - dt
	if self.burrowTick <= 0  and self.burrowing then
		if not playerModified(mcontroller.position(),1) then
	    	world.spawnProjectile(self.burrowProjectile, mcontroller.position())
	    end
	    self.burrowTick = self.burrowTimer
	end
    end
    self.burrowed = self.burrowing
end

function twistEffect()
	self.twist = self.twist and self.twist or 0
	self.newTwist = vec2.angle(mcontroller.velocity())
	animator.rotateTransformationGroup("body", self.twist - self.newTwist)
	self.twist = self.newTwist
end

function update(dt)

	self.parent = self.parent and self.parent or config.getParameter("parent")
	
	if not self.burrowTimer then
	  self.burrowProjectile = config.getParameter("burrowProjectile", "burrow")
	  self.burrowBurstProjectile = config.getParameter("burrowBurstProjectile", "burrowburst")
	  self.burrowTimer = config.getParameter("burrowTimer",0.25)
	  self.burrowTick = self.burrowTimer
	  self.burrowPoly = config.getParameter("burrowPoly",{ {-0.45, -0.25},{-0.25, -0.45}, {0.25, -0.45}, {0.45, -0.25}, {0.45, 0.25}, {0.25, 0.45}, {-0.25, 0.45}, {-0.45, 0.25} })
	end

	if not self.followRadius then
	  monster.setDamageBar("none")
	  self.parentRadius =  config.getParameter("parentRadius",1)
	  local segmentRadius = config.getParameter("radius",1)
	  self.followRadius =  segmentRadius + self.parentRadius
	  local movementSettings = config.getParameter("movementSettings")
	  self.flySpeed = movementSettings.flySpeed
	end
	
	if not self.statusEffectChecked then
		local projectileCoordinator = config.getParameter('projectileCoordinator')
		if projectileCoordinator then
			status.addEphemeralEffect(projectileCoordinator,1)
		end
		self.statusEffectChecked = true
	end

	self.monsterUpdate = self.monsterUpdate and self.monsterUpdate or monsterUpdate
	self.monsterUpdate(dt)
	
	if world.entityExists(self.parent and self.parent or -1) then
		local distance 	= entity.distanceToEntity(self.parent)
		local angle 	= vec2.angle(distance)
		local magnitude = world.magnitude(mcontroller.position(),world.entityPosition(self.parent))
		self.tilt = self.tilt and self.tilt or angle
		if magnitude > self.followRadius * 2 then
			mcontroller.setPosition(world.entityPosition(self.parent))
		end
		if world.magnitude(mcontroller.position(),world.entityPosition(self.parent)) > self.followRadius then
		  mcontroller.controlApproachVelocityAlongAngle(angle, self.flySpeed + magnitude, 1500)
		twistEffect()
		else
		  mcontroller.setVelocity(vec2.approach(distance,world.entityPosition(self.parent),self.parentRadius))
		end
	end

	burrowEffect(dt)

end

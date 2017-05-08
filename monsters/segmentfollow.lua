require "/scripts/vec2.lua"
local monsterUpdate = update

function update(dt)
	self.parent = self.parent and self.parent or config.getParameter("parent")
	if not self.followRadius then
	  self.parentRadius =  config.getParameter("parentRadius",1)
	  local segmentRadius = config.getParameter("radius",1)
	  self.followRadius =  segmentRadius + self.parentRadius
	  local movementSettings = config.getParameter("movementSettings")
	  self.flySpeed = movementSettings.flySpeed
	end	
	monsterUpdate(dt)
	if world.entityExists(self.parent and self.parent or -1) then
		local distance 	= entity.distanceToEntity(self.parent)
		local angle 	= vec2.angle(distance)
		local magnitude = world.magnitude(mcontroller.position(),world.entityPosition(self.parent))
		if magnitude > self.followRadius * 2 then
			mcontroller.setPosition(world.entityPosition(self.parent))
		end
		if world.magnitude(mcontroller.position(),world.entityPosition(self.parent)) > self.followRadius then
		mcontroller.controlApproachVelocityAlongAngle(angle, self.flySpeed + magnitude, 1500)
		else
		mcontroller.setVelocity(vec2.approach(distance,world.entityPosition(self.parent),self.parentRadius))
		end
		
	end
end

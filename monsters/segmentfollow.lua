require "/scripts/vec2.lua"
local monsterUpdate = update

function update(dt)
	self.parent = self.parent and self.parent or config.getParameter("parent")
	monsterUpdate(dt)
	if world.entityExists(self.parent) then
		--[[local target = {world.entityPosition(self.parent)[1] + distance[1], world.entityPosition(self.parent)[2] + distance[2]}
		monster.flyTo(target)]]
		local distance = entity.distanceToEntity(self.parent)
		local angle = vec2.angle(distance)
		local magnitude = world.magnitude(mcontroller.position(),world.entityPosition(self.parent))
		print(magnitude)		
		if world.magnitude(mcontroller.position(),world.entityPosition(self.parent)) > 2 then
		mcontroller.controlApproachVelocityAlongAngle(angle, 15 + magnitude, 1000)
		else
		mcontroller.setVelocity(vec2.approach(distance,world.entityPosition(self.parent),1))
		end
		
	end
end

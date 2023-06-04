require "/scripts/messageutil.lua"

function init()
	self.techstationUid = config.getParameter("techstationUid")
	if world.pointTileCollision(entity.position()) then
		promises:add(world.findUniqueEntity(self.techstationUid), function(position)
			self.techstationLocation = position
		end)
	else
		effect.expire()
	end
end

function update(dt)
	promises:update()
	if self.techstationLocation then
		mcontroller.setPosition(self.techstationLocation)
		effect.expire()
	end
end
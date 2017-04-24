local monsterUpdate = update

function update(dt)
	monsterUpdate(dt)
	self.parent = self.parent and self.parent or config.getParameter("parent")
	distance = entity.distanceToEntity(self.parent)
	if math.abs(distance[1] + distance[2]) > 4 then
		newPosition = {(world.entityPosition(self.parent)[1]+mcontroller.position()[1])/2,(world.entityPosition(self.parent)[2]+mcontroller.position()[2])/2}
		mcontroller.setPosition(newPosition)
	end

end

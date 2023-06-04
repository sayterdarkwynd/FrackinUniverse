function init()
	counter = 0
	worldType = world.type()
end

function update(dt)
	if worldType ~= "unknown" then
		if counter == 1 then
			local worldHeight = world.size()[2]
			mcontroller.setYPosition(worldHeight)
			effect.expire()
		else
			counter = 1
		end
	end
end
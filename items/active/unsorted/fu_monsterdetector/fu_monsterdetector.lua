function activate(fireMode)
	local targetlist = world.entityQuery(world.entityPosition(player.id()),50,{includedTypes={"monster"}})
	for key, value in pairs(targetlist) do
		world.sendEntityMessage(value,"applyStatusEffect","minibossglow",30)
	end
end

function update()
	if mcontroller.crouching() then
		activeItem.setArmAngle(-0.15)
	else
		activeItem.setArmAngle(-0.5)
	end
end
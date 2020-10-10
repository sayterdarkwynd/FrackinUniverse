require "/scripts/effectUtil.lua"

function activate(fireMode)
	effectUtil.effectTypesInRange("minibossglow",50,{"monster"},30)
	--[[local targetlist = world.entityQuery(world.entityPosition(player.id()),50,{includedTypes={"monster"}})
	for key, value in pairs(targetlist) do
		world.sendEntityMessage(value,"applyStatusEffect","minibossglow",30)
	end]]
end

function update()
	if mcontroller.crouching() then
		activeItem.setArmAngle(-0.15)
	else
		activeItem.setArmAngle(-0.5)
	end
end
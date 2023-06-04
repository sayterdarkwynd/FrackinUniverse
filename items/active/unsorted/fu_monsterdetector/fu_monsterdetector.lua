require "/scripts/effectUtil.lua"
require "/scripts/epoch.lua"

function init()
	checkIsTheDate(true)
end

function activate(fireMode)
	effectUtil.effectTypesInRange("minibossglow",50,isTheDate and {"player"} or {"monster"},30)
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

function checkIsTheDate(atInit)
	local epoDat=epoch.currentToTable()
	if epoDat.day==31 and epoDat.month==10 then
		if atInit or not isTheDate then
			isTheDate=true
		end
	else
		if atInit or isTheDate then
			isTheDate=false
		end
	end
end
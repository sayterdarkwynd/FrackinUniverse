require "/scripts/kheAA/transferUtil.lua"

function init()
	delayInit=true
end

function delayedInit()
	containerCallback()
	object.setInteractive(true)
	delayInit=false
end

function update(dt)
	if not transferUtilDeltaTime or (transferUtilDeltaTime > 1) then
		transferUtilDeltaTime=0
		transferUtil.loadSelfContainer()
	else
		transferUtilDeltaTime=transferUtilDeltaTime+dt
	end
	if delayInit then
		delayedInit()
	end
	--[[if not smartboxCompareTimer or (smartboxCompareTimer > 1) then
		smartboxCompareTimer=0
		containerCallback()
	else
		smartboxCompareTimer=smartboxCompareTimer+dt
	end]]
end

function containerCallback()
	local items=world.containerItems(entity.id())
	local answer=(items and items[1] and items[2]) and (compare(items[1],items[2]))
	object.setOutputNodeLevel(1,answer)
	animator.setAnimationState("routerState",answer and "on" or "off")
end

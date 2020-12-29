require '/scripts/fupower.lua'
require "/scripts/kheAA/transferUtil.lua"

function init()
	heat = config.getParameter('heat')
	power.init()
end

function update(dt)
	if not transferUtilDeltaTime or (transferUtilDeltaTime > 1) then
		transferUtilDeltaTime=0
		transferUtil.loadSelfContainer()
	else
		transferUtilDeltaTime=transferUtilDeltaTime+dt
	end

	if storage.fueltime and storage.fueltime > 0 then
		storage.fueltime = math.max(storage.fueltime - dt,0)
	end
	if (not storage.fueltime or storage.fueltime == 0) and (not object.isInputNodeConnected(1) or object.getInputNodeLevel(1)) then
		item = world.containerItemAt(entity.id(),0)
		if item then
			itemlist = config.getParameter('acceptablefuel')
			if itemlist[item.name] then
				world.containerConsumeAt(entity.id(),0,1)
				storage.fueltime = itemlist[item.name]
			end
		end
	end
	if storage.fueltime and storage.fueltime > 0 then
		storage.heat = math.min((storage.heat or 0) + dt*5,100)
	else
		storage.heat = math.max((storage.heat or 0) - dt*5,0)
	end
	local heatmark=0
	for i=1,#heat do
		if storage.heat >= heat[i].minheat then
			heatmark=heat[i].power
			power.setPower(heatmark)
			object.setLightColor(config.getParameter("lightColor", heat[i].light))
			object.setSoundEffectEnabled(heat[i].sound)
			for key,value in pairs(heat[i].animator) do
				animator.setAnimationState(key, value)
			end
			break
		end
	end
	object.setAllOutputNodes(heatmark>0)
	power.update(dt)
end

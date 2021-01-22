require '/scripts/fupower.lua'
require "/scripts/kheAA/transferUtil.lua"

function init()
	heat = config.getParameter('heat')
	fuellist = config.getParameter('acceptablefuel')
	objectlight=config.getParameter("lightColor")
	power.init()
end
function update(dt)
	if not transferUtilDeltaTime or (transferUtilDeltaTime > 1) then
		transferUtilDeltaTime=0
		transferUtil.loadSelfContainer()
	else
		transferUtilDeltaTime=transferUtilDeltaTime+dt
	end
	storage.fueltime = math.max((storage.fueltime or dt) - dt,0)
	if storage.fueltime == 0 then
		storage.powermod = nil
		if (not object.isInputNodeConnected(0) or object.getInputNodeLevel(0)) then
			fuel = world.containerItemAt(entity.id(),0)
			neutronium = world.containerItemAt(entity.id(),1)
			antineutronium = world.containerItemAt(entity.id(),2)
			if neutronium and antineutronium and neutronium.name=="neutronium" and antineutronium.name=="antineutronium" then
				if fuel then
					for key,value in pairs(fuellist) do
						if fuel.name == key then
							world.containerConsumeAt(entity.id(),0,1)
							storage.fueltime = value
							storage.powermod = value
						end
					end
				end
			end
		end
	end
	storage.heat = math.min((storage.heat or 0) + dt*5,((storage.fueltime and (storage.fueltime > 0)) and 100) or 0)
	local powerValue=0
	for i=1,#heat do
		if storage.heat >= heat[i].minheat then
			powerValue=heat[i].power + (storage.powermod or 0)
			power.setPower(powerValue)
			local light = objectlight or heat[i].light or {0,0,0} --note that the latter 2 likely never get used.
			local brightness = math.min(0.75,0.75*(storage.heat/90))
			object.setLightColor({math.floor(light[1]*0.25 + light[1]*brightness),math.floor(light[2]*0.25 + light[2]*brightness),math.floor(light[3]*0.25 + light[3]*brightness)})
			object.setSoundEffectEnabled(heat[i].sound)
			for key,value in pairs(heat[i].animator) do
				animator.setAnimationState(key, value)
			end
			break
		end
	end
	object.setAllOutputNodes(powerValue>0)
	power.update(dt)
end
require "/scripts/util.lua"
power = {}

function power.update(dt)
	if not power.didInit then
		power.init()
	end
	if not power.warmedUp then
		power.kick()
		power.warmedUp=true
	end
	if power.objectPowerType then
		-- luacheck: ignore 122
		if object.pulseTimer and object.pulseTimer >= 1.0 then
			object.pulseTimer=0.0
			local inputCounter=0
			local outputCounter=0
			for i=0,object.inputNodeCount()-1 do
				if object.isInputNodeConnected(i) then
					local idlist = object.getInputNodeIds(i)
					inputCounter=inputCounter+util.tableSize(idlist)
				end
			end
			for i=0,object.outputNodeCount()-1 do
				if object.isOutputNodeConnected(i) then
					local idlist = object.getOutputNodeIds(i)
					outputCounter=outputCounter+util.tableSize(idlist)
				end
			end
			if (power.pulseCounter and (power.pulseCounter>=10)) or ((power.objectPowerType ~= 'battery') and ((power.lastInputCount~=inputCounter) or (power.lastOutputCount~=outputCounter))) then
				power.kick()
			elseif power.pulseCounter and power.pulseCounter<10 then
				power.pulseCounter=power.pulseCounter+1
			end
		else
			object.pulseTimer=(object.pulseTimer or 0) + dt
		end
		if power.objectPowerType == 'battery' then
			storage.storedenergy = (storage.storedenergy or 0) + (storage.energy or 0)
		else
			power.sendPowerToBatteries()
		end
		if storage.power and storage.power > 0 then
			storage.energy = storage.power * dt
			if power.objectPowerType == 'battery' then
				storage.energy = math.min(storage.power,storage.storedenergy)
				storage.storedenergy = storage.storedenergy - storage.energy
			end
		else
			storage.energy = 0
		end
	end
end

function power.consume(amount)
	if (type(amount)=="number") then
		if (amount>0) then
			if power.getTotalEnergy() >= amount then
				for i=1,#power.entitylist.output do
					energy = power.getEnergy(power.entitylist.output[i])
					if energy > 0 then
						energy = math.min(energy,amount)
						callEntity(power.entitylist.output[i],'power.remove',energy)
						amount = amount - energy
					end
					if amount == 0 then
						return true
					end
				end
				for i=1,#power.entitylist.battery do
					energy = power.getEnergy(power.entitylist.battery[i])
					if energy > 0 then
						energy = math.min(energy,amount)
						callEntity(power.entitylist.battery[i],'power.remove',energy)
						amount = amount - energy
					end
					if amount == 0 then
						return true
					end
				end
			else
				return false
			end
		else
			return true
		end
	end
end

function power.sendPowerToBatteries()
	if (type(power.entitylist)=="table") and (type(power.entitylist.battery)=="table") then
		if (storage.energy or 0) > 0 then
			for _,value in pairs(power.entitylist.battery) do
				amount = math.min((storage.energy or 0),(callEntity(value,'power.getStorageLeft') or 0))
				storage.energy = (storage.energy or 0) - amount
				callEntity(value,'power.receivePower',amount)
				if storage.energy == 0 then
					break
				end
			end
		end
	end
end

function power.onNodeConnectionChange(arg,iterations)
	if power.objectPowerType then
		local inputCounter=0
		local outputCounter=0
		if (power.objectPowerType == 'battery') then return arg end
		--sb.logInfo("iterations: %s",iterations)
		iterations=(iterations and iterations + 1) or 1
		if arg then
			entitylist = arg
		else
			if power.objectPowerType == 'battery' then
				entitylist = {battery = {entity.id()},output = {},all = {entity.id()}}
			elseif power.objectPowerType == 'output' then
				entitylist = {battery = {},output = {entity.id()},all = {entity.id()}}
			else
				entitylist = {battery = {},output = {},all = {entity.id()}}
			end
		end

		-- Update "entitylist" by querying every entity that has its IDs listed in "idlist" array.
		local function updateEntityList(idlist, iterations2)
			for value in pairs(idlist) do
				powertype = callEntity(value,'isPower',iterations2)
				if powertype then
					for j=1,#entitylist.all+1 do
						if j == #entitylist.all+1 then
							if powertype == 'battery' then
								table.insert(entitylist.battery,value)
							elseif powertype == 'output' then
								table.insert(entitylist.output,value)
							end

							table.insert(entitylist.all,value)
							entitylist = (callEntity(value,'power.onNodeConnectionChange',entitylist,iterations2) or entitylist)
						elseif entitylist.all[j] == value then
							break
						end
					end
				end
			end
		end

		if iterations < 100 then
			for i=0,object.inputNodeCount()-1 do
				if object.isInputNodeConnected(i) then
					local idlist = object.getInputNodeIds(i)
					inputCounter=inputCounter+util.tableSize(idlist)

					updateEntityList(idlist, iterations)
				end
			end
			for i=0,object.outputNodeCount()-1 do
				if object.isOutputNodeConnected(i) then
					local idlist = object.getOutputNodeIds(i)
					outputCounter=outputCounter+util.tableSize(idlist)

					updateEntityList(idlist, iterations)
				end
			end
		else
			sb.logWarn("fupower.lua:power.onNodeConnectionChange: Critical recursion threshhold reached!")
		end
		if arg then
			return entitylist
		else
			power.entitylist = entitylist
			for i=2,#entitylist.all do
				callEntity(entitylist.all[i],'updateList',entitylist)
			end
		end
		power.lastInputCount=inputCounter
		power.lastOutputCount=outputCounter
	end
end

function power.getTotalEnergy()
	local energy = 0
	if type(power.entitylist)=="table" then
		if type(power.entitylist.output)=="table" then
			for i=1,#power.entitylist.output do
				energy = energy + power.getEnergy(power.entitylist.output[i])
			end
		end
		if type(power.entitylist.battery)=="table" then
			for i=1,#power.entitylist.battery do
				energy = energy + power.getEnergy(power.entitylist.battery[i])
			end
		end
	end
	return energy
end

function power.getTotalEnergyNoBattery()
	local energy = 0
	if type(power.entitylist)=="table" then
		if type(power.entitylist.output)=="table" then
			for i=1,#power.entitylist.output do
				energy = energy + power.getEnergyNoBattery(power.entitylist.output[i])
			end
		end
		if type(power.entitylist.battery)=="table" then
			for i=1,#power.entitylist.battery do
				energy = energy + power.getEnergyNoBattery(power.entitylist.battery[i])
			end
		end
	end
	return energy
end

function power.getEnergy(id)
	if not id or id == entity.id() then
		return storage.energy or 0
	else
		return callEntity(id,'power.getEnergy') or 0
	end
end

function power.getEnergyNoBattery(id)
	if not id or id == entity.id() then
		return ((power.objectPowerType ~= 'battery') and storage.energy) or 0
	else
		return callEntity(id,'power.getEnergyNoBattery') or 0
	end
end

function onNodeConnectionChange(arg)
	power.onNodeConnectionChange(nil,0)
end

function isPower()
	return power.objectPowerType
end

function updateList(list)
	power.entitylist = list
end

function callEntity(id,...)
	if world.entityExists(id) then
		local pass,result=pcall(world.callScriptedEntity,id,...)
		return pass and result
	else
		power.warmedUp=false
	end
end

function power.receivePower(amount)
	storage.storedenergy = (storage.storedenergy or 0) + amount
end

function power.setStoredEnergy(energy)
	storage.storedenergy = (energy or 0)
end

function power.setMaxEnergy(energy)
	storage.maxenergy = (energy or 0)
end

function power.getMaxEnergy()
	return storage.maxenergy
end

function power.setPower(power)
	storage.power = power or 0
end

function power.getStorageLeft()
	return (storage.maxenergy or 0) - power.getStoredEnergy()
end

function power.getStoredEnergy()
	return (storage.storedenergy or 0) + (storage.energy or 0)
end

function power.remove(amount)
	storage.energy = storage.energy - amount
end

function power.kick()
	power.pulseCounter=0
	power.onNodeConnectionChange(nil,0)
end

function power.init()
	power.objectPowerType=config.getParameter('powertype')
	power.kick()
	power.didInit=true
end

function update(dt)
	power.update(dt)
end

function init()
	power.init()
end

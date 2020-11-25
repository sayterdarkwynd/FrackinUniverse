power = {}

function power.update(dt)
	if not power.warmedUp then
		power.init()
		power.warmedUp=true
	end
	if config.getParameter('powertype') then
		if config.getParameter('powertype') == 'battery' then
			storage.storedenergy = (storage.storedenergy or 0) + (storage.energy or 0)
		else
			power.sendPowerToBatteries()
		end
		if storage.power and storage.power > 0 then
			storage.energy = storage.power * dt
			if config.getParameter('powertype') == 'battery' then
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
				for i=1,#self.entitylist.output do
					energy = power.getEnergy(self.entitylist.output[i])
					if energy > 0 then
						energy = math.min(energy,amount)
						callEntity(self.entitylist.output[i],'power.remove',energy)
						amount = amount - energy
					end
					if amount == 0 then
						return true
					end
				end
				for i=1,#self.entitylist.battery do
					energy = power.getEnergy(self.entitylist.battery[i])
					if energy > 0 then
						energy = math.min(energy,amount)
						callEntity(self.entitylist.battery[i],'power.remove',energy)
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
	if (type(self.entitylist)=="table") and (type(self.entitylist.battery)=="table") then
		if (storage.energy or 0) > 0 then
			for key,value in pairs(self.entitylist.battery) do
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
	if config.getParameter('powertype') then
		if (config.getParameter('powertype') == 'battery') then return arg end
		--sb.logInfo("iterations: %s",iterations)
		iterations=(iterations and iterations + 1) or 1
		if arg then
			entitylist = arg
		else
			if config.getParameter('powertype') == 'battery' then
				entitylist = {battery = {entity.id()},output = {},all = {entity.id()}}
			elseif config.getParameter('powertype') == 'output' then
				entitylist = {battery = {},output = {entity.id()},all = {entity.id()}}
			else
				entitylist = {battery = {},output = {},all = {entity.id()}}
			end
		end
		if iterations < 100 then
			for i=0,object.inputNodeCount()-1 do
				if object.isInputNodeConnected(i) then
					local idlist = object.getInputNodeIds(i)
					for value in pairs(idlist) do
						powertype = callEntity(value,'isPower',iterations)
						if powertype then
							for j=1,#entitylist.all+1 do
								if j == #entitylist.all+1 then
									if powertype == 'battery' then
										table.insert(entitylist.battery,value)
									elseif powertype == 'output' then
										table.insert(entitylist.output,value)
									end
									table.insert(entitylist.all,value)
									entitylist = (callEntity(value,'power.onNodeConnectionChange',entitylist,iterations) or entitylist)
								elseif entitylist.all[j] == value then
									break
								end
							end
						end
					end
				end
			end
			for i=0,object.outputNodeCount()-1 do
				if object.isOutputNodeConnected(i) then
					local idlist = object.getOutputNodeIds(i)
					for value in pairs(idlist) do
						powertype = callEntity(value,'isPower',iterations)
						if powertype then
							for j=1,#entitylist.all+1 do
								if j == #entitylist.all+1 then
									if powertype == 'battery' then
										table.insert(entitylist.battery,value)
									elseif powertype == 'output' then
										table.insert(entitylist.output,value)
									end
									table.insert(entitylist.all,value)
									entitylist = (callEntity(value,'power.onNodeConnectionChange',entitylist,iterations) or entitylist)
								elseif entitylist.all[j] == value then
									break
								end
							end
						end
					end
				end
			end
		else
			sb.logWarn("fupower.lua:power.onNodeConnectionChange: Critical recursion threshhold reached!")
		end
		if arg then
			return entitylist
		else
			self.entitylist = entitylist
			for i=2,#entitylist.all do
				callEntity(entitylist.all[i],'updateList',entitylist)
			end
		end
	end
end

function power.getTotalEnergy()
	local energy = 0
	if type(self.entitylist)=="table" then
		if type(self.entitylist.output)=="table" then
			for i=1,#self.entitylist.output do
				energy = energy + power.getEnergy(self.entitylist.output[i])
			end
		end
		if type(self.entitylist.battery)=="table" then
			for i=1,#self.entitylist.battery do
				energy = energy + power.getEnergy(self.entitylist.battery[i])
			end
		end
	end
	return energy
end

function power.getTotalEnergyNoBattery()
	local energy = 0
	if type(self.entitylist)=="table" then
		if type(self.entitylist.output)=="table" then
			for i=1,#self.entitylist.output do
				energy = energy + power.getEnergyNoBattery(self.entitylist.output[i])
			end
		end
		if type(self.entitylist.battery)=="table" then
			for i=1,#self.entitylist.battery do
				energy = energy + power.getEnergyNoBattery(self.entitylist.battery[i])
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
		return ((config.getParameter('powertype') ~= 'battery') and storage.energy) or 0
	else
		return callEntity(id,'power.getEnergyNoBattery') or 0
	end
end

function onNodeConnectionChange(arg)
	power.onNodeConnectionChange(nil,0)
end

function isPower()
	return config.getParameter('powertype')
end

function updateList(list)
	self.entitylist = list
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

function power.init()
	power.onNodeConnectionChange(nil,0)
end

function update(dt)
	power.update(dt)
end

function init()
	power.init()
end
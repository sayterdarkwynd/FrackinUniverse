power = {}

function power.init()
  power.onNodeConnectionChange()
end

function init()
  power.init()
end

function power.update(dt)
  if config.getParameter('powertype') then
    if config.getParameter('powertype') == 'battery' then
      storage.storedenergy = (storage.storedenergy or 0) + (storage.energy or 0)
    else
      power.sendPowerToBatteries()
    end
    if storage.power and storage.power > 0 then
      storage.energy = storage.power * dt
	  if config.getParameter('powertype') == 'battery' then
	    storage.energy = math.min(storage.energy,storage.storedenergy)
        storage.storedenergy = storage.storedenergy - storage.energy
      end
    else
      storage.energy = 0
    end
  end
end

function update(dt)
  power.update(dt)
end

function power.getStorageLeft()
  return (storage.maxenergy or 0) - (storage.storedenergy or 0) - (storage.energy or 0)
end

function power.getStoredEnergy()
  return (storage.storedenergy or 0) + (storage.energy or 0)
end

function power.remove(amount)
  storage.energy = storage.energy - amount
end

function power.consume(amount)
    if power.getTotalEnergy() >= amount then
    for i=1,#storage.entitylist.output do
      energy = power.getEnergy(storage.entitylist.output[i])
      if energy > 0 then
        energy = math.min(energy,amount)
  	    world.callScriptedEntity(storage.entitylist.output[i],'power.remove',energy)
  	    amount = amount - energy
      end
      if amount == 0 then
        return true
      end
    end
    for i=1,#storage.entitylist.battery do
      energy = power.getEnergy(storage.entitylist.battery[i])
      if energy > 0 then
        energy = math.min(energy,amount)
  	  world.callScriptedEntity(storage.entitylist.battery[i],'power.remove',energy)
  	  amount = amount - energy
      end
      if amount == 0 then
        return true
      end
    end
  else
    return false
  end
end

function power.sendPowerToBatteries()
  if (storage.energy or 0) > 0 then
    for key,value in pairs(storage.entitylist.battery) do
      amount = math.min((storage.energy or 0),world.callScriptedEntity(value,'power.getStorageLeft'))
	  storage.energy = (storage.energy or 0) - amount
	  world.callScriptedEntity(value,'power.recievePower',amount)
	  if storage.energy == 0 then
	    break
	  end
	end
  end
end

function power.recievePower(amount)
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

function power.getTotalEnergy()
  local energy = 0
  for i=1,#storage.entitylist.output do
	energy = energy + power.getEnergy(storage.entitylist.output[i])
  end
  for i=1,#storage.entitylist.battery do
	energy = energy + power.getEnergy(storage.entitylist.battery[i])
  end
  return energy
end

function power.getEnergy(id)
  if not id or id == entity.id() then
    return storage.energy or 0
  else
    return world.callScriptedEntity(id,'power.getEnergy') or 0
  end
end

function onNodeConnectionChange()
  power.onNodeConnectionChange()
end

function power.onNodeConnectionChange(arg)
  if config.getParameter('powertype') then
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
  
    for i=0,object.inputNodeCount()-1 do
      if object.isInputNodeConnected(i) then
	    local idlist = object.getInputNodeIds(i)
	    for value in pairs(idlist) do
	      powertype = world.callScriptedEntity(value,'isPower')
	      if powertype then
	        for j=1,#entitylist.all+1 do
		      if j == #entitylist.all+1 then
			    if powertype == 'battery' then
			      table.insert(entitylist.battery,value)
			    elseif powertype == 'output' then
			      table.insert(entitylist.output,value)
			    end
		        table.insert(entitylist.all,value)
			    entitylist = world.callScriptedEntity(value,'power.onNodeConnectionChange',entitylist)
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
	      powertype = world.callScriptedEntity(value,'isPower')
	      if powertype then
	        for j=1,#entitylist.all+1 do
		      if j == #entitylist.all+1 then
			    if powertype == 'battery' then
			      table.insert(entitylist.battery,value)
			    elseif powertype == 'output' then
			      table.insert(entitylist.output,value)
			    end
		        table.insert(entitylist.all,value)
			    entitylist = world.callScriptedEntity(value,'power.onNodeConnectionChange',entitylist)
		      elseif entitylist.all[j] == value then
		        break
		      end
		    end
		  end
		end
	  end
	end
    if arg then
      return entitylist
    else
      storage.entitylist = entitylist
      for i=2,#entitylist.all do
        world.callScriptedEntity(entitylist.all[i],'updateList',entitylist)
	  end
    end
  end
end

function isPower()
  return config.getParameter('powertype')
end

function updateList(list)
  storage.entitylist = list
end
require "/scripts/kheAA/transferUtil.lua"
local deltatime = 0;

function init()
	transferUtil.init()
	storage.receiveItems=true
	storage.prevContainer = storage.containerID
	local temp=transferUtil.updateInputs(0,1)
	transferUtil.updateOutputs(0,0)
	object.setOutputNodeLevel(0,temp or (storage.containerID~=nil))
end


function findContainer()
	storage.containerID = nil
	local objectIds = world.objectQuery(entity.position(), 50, { order = "nearest" })
	for _, objectId in ipairs(objectIds) do
		if world.containerSize(objectId) then
			storage.containerID = objectId
			table.insert(storage.inContainers,objectId)
			table.insert(storage.outContainers,objectId)
			break
		end
	end 
end

function checkSaystorageChange( ... )
	if storage.containerID ~= storage.prevContainer then
		if storage.containerID == nil then
			sayText = "Disconnected!"
		else 
			sayText = "Connected to:"..world.entityName(storage.containerID)
		end
	end
	storage.prevContainer = storage.containerID
end

function update(dt)
	deltatime = deltatime + dt;
	if deltatime < 1 then
		return;
	end
	if sayText ~= nil then
		object.say(sayText)
		sayText = nil
	end
	local temp=transferUtil.updateInputs(0,1)
	transferUtil.updateOutputs(0,0)
	if not storage.containerID or not world.entityExists(storage.containerID) then
		findContainer()
	end
	checkSaystorageChange()	
	object.setOutputNodeLevel(0,temp or (storage.containerID~=nil))
end
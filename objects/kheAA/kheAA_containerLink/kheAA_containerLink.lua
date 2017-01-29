require "/scripts/kheAA/transferUtil.lua"
local deltatime = 0;


function init()
	transferUtil.init()
	storage.receiveItems=true
	storage.containerID=nil
	--storage.prevContainer=nil
	local temp=transferUtil.updateInputs(0,1)
	transferUtil.updateOutputs(0,0)
	object.setOutputNodeLevel(0,temp or (storage.containerID~=nil))
	powerNode=0
	inDataNode=1
	outDataNode=0
end


function findContainer()
	storage.containerID = nil
	local objectIds = world.objectQuery(entity.position(), 50, { order = "nearest" })
	for _, objectId in ipairs(objectIds) do
		if world.containerSize(objectId) then
			storage.containerID = objectId
			transferUtil.tConjunct(storage.inContainers,{storage.containerID})
			transferUtil.tConjunct(storage.outContainers,{storage.containerID})
			break
		end
	end 
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
	findContainer()
	storage.inContainers={storage.containerID}
	storage.outContainers={storage.containerID}
	object.setOutputNodeLevel(0,true)
end
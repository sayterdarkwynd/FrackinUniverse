require "/scripts/kheAA/transferUtil.lua"
local deltatime = 0;


function init()
	transferUtil.init()
	storage.receiveItems=true
	inDataNode=0
	outDataNode=0
	storage.inContainers={}
	storage.outContainers={}
end


function findContainer()
	local objectIds = world.objectQuery(entity.position(), 50, { order = "nearest" })
	for _, objectId in pairs(objectIds) do
		if world.containerSize(objectId) then
			storage.inContainers[objectId]=0
			storage.outContainers[objectId]=0
			break
		end
	end 
end

function update(dt)
	deltatime = deltatime + dt;
	if deltatime < 1 then
		return;
	end
	deltatime=0
	storage.inContainers={}
	storage.outContainers={}
	findContainer()
	object.setOutputNodeLevel(outDataNode,util.tableSize(storage.outContainers)>0)
end
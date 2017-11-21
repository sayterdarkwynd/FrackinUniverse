require "/scripts/kheAA/transferUtil.lua"

function init()
	transferUtil.init()
	storage.inContainers={}
	storage.outContainers={}
	storage.containerId=nil
	storage.containerPos={0,0}
	storage.linkRange=config.getParameter("kheAA_linkRange",16)
end

function update(dt)
	deltatime = (deltatime or 0) + dt;
	if deltatime < 1 then
		return;
	end
	deltatime=0
	findContainer()
	object.setOutputNodeLevel(storage.outDataNode,not storage.containerId==nil)
end

function findContainer()
	if storage.containerId == nil then
		local tempRect=transferUtil.pos2Rect(storage.position,storage.linkRange)
		if not world.regionActive(temprect) then
			world.loadRegion(tempRect)
		end
	elseif not world.regionActive(transferUtil.pos2Rect(storage.containerPos,1)) then
		world.loadRegion(transferUtil.pos2Rect(storage.containerPos,1))
		if not world.entityExists(storage.containerId) then
			storage.containerId=nil
		end
	end

	local objectIds = world.objectQuery(entity.position(), storage.linkRange, { order = "nearest" })
	for _, objectId in pairs(objectIds) do
		if world.containerSize(objectId) and not world.getObjectParameter(objectId,"notItemStorage",false) then
			storage.containerId=objectId
			storage.containerPos=world.entityPosition(storage.containerId)
			storage.inContainers[storage.containerId]=storage.containerPos
			storage.outContainers[storage.containerId]=storage.containerPos
			break
		end
	end 
end

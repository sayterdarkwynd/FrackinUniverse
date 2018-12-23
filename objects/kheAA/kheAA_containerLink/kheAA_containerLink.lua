require "/scripts/kheAA/transferUtil.lua"

function init()
	transferUtil.init()
	storage.inContainers={}
	storage.outContainers={}
	storage.containerId=nil
	storage.containerPos={0,0}
	storage.linkRange=config.getParameter("kheAA_linkRange",16)
	storage.outPartialFillNode=config.getParameter("kheAA_outPartialFillNode")
	storage.outCompleteFillNode=config.getParameter("kheAA_outCompleteFillNode")
	
	local desc="^blue;Input: ^white;item network^reset;\n^red;Output: ^white;item network^reset;"
	if storage.outPartialFillNode then
		desc=desc.."^red;Lower output: ^white;item network^reset;\n^red;Upper outputs: ^white;Partial/Complete Fill^reset;"
	end
	object.setConfigParameter('description',desc)
end

function update(dt)
	deltatime = (deltatime or 0) + dt;
	if deltatime < 1 then
		return;
	end
	deltatime=0
	findContainer()
	object.setOutputNodeLevel(storage.outDataNode,not storage.containerId==nil)
	
	

	if storage.outPartialFillNode or storage.outCompleteFillNode then
		storage.containerSize=world.containerSize(storage.containerId)
		storage.containerFill=util.tableSize(world.containerItems(storage.containerId) or {})
		
		if storage.outPartialFillNode then
			object.setOutputNodeLevel(storage.outPartialFillNode,(storage.containerFill or 0) > 0)
		end
		if storage.outCompleteFillNode then
			object.setOutputNodeLevel(storage.outCompleteFillNode,(storage.containerFill and storage.containerSize) and (storage.containerFill==storage.containerSize))
		end
	end

end

function findContainer()
	transferUtil.zoneAwake(transferUtil.pos2Rect(storage.position,storage.linkRange))
	storage.containerId=nil
	storage.containerPos=nil
	storage.inContainers={}
	storage.outContainers={}
	
	local objectIds = world.objectQuery(storage.position, storage.linkRange, { order = "nearest" })
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

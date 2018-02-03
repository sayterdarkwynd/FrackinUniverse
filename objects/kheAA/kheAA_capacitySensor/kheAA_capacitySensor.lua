require "/scripts/util.lua"

function init()
	storage.containerId=nil
	storage.linkRange=config.getParameter("kheAA_linkRange",16)
	storage.outPartialFillNode=config.getParameter("kheAA_outPartialFillNode")
	storage.outCompleteFillNode=config.getParameter("kheAA_outCompleteFillNode")
end

function update(dt)
	deltatime = (deltatime or 0) + dt;
	if deltatime < 1 then
		return;
	end
	deltatime=0
	findContainer()

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
	local objectIds = world.objectQuery(entity.position(), storage.linkRange, { order = "nearest" })
	for _, objectId in pairs(objectIds) do
		if world.containerSize(objectId) and not world.getObjectParameter(objectId,"notItemStorage",false) then
			storage.containerId=objectId
			break
		end
	end 
end

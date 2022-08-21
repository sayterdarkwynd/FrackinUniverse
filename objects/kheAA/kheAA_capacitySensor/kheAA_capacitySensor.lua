require "/scripts/util.lua"

function init()
	self.containerId=nil
	self.linkRange=config.getParameter("kheAA_linkRange",16)
	self.outPartialFillNode=config.getParameter("kheAA_outPartialFillNode")
	self.outCompleteFillNode=config.getParameter("kheAA_outCompleteFillNode")

	object.setConfigParameter('description',"^red;Output1:^reset; Partial Fill ^red;Output2:^reset; Complete Fill")
end

function update(dt)
	deltatime = (deltatime or 0) + dt;
	if deltatime < 1 then
		return
	end
	deltatime=0
	local size=findContainer()

	if size and (self.outPartialFillNode or self.outCompleteFillNode) then
		local containerFill=util.tableSize(world.containerItems(self.containerId) or {})

		if self.outPartialFillNode then
			object.setOutputNodeLevel(self.outPartialFillNode,(containerFill or 0) > 0)
		end
		if self.outCompleteFillNode then
			object.setOutputNodeLevel(self.outCompleteFillNode,(containerFill and size) and (containerFill==size))
		end
	end
end

function findContainer()
	local objectIds = world.objectQuery(entity.position(), self.linkRange, { order = "nearest" })
	for _, objectId in pairs(objectIds) do
		local sSize=world.containerSize(objectId)
		if sSize and not world.getObjectParameter(objectId,"notItemStorage",false) then
			self.containerId=objectId
			return sSize
		end
	end
end

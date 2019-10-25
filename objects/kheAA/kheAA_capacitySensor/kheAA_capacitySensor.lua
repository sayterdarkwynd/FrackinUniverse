require "/scripts/util.lua"

function init()
	self.containerId=nil
	self.linkRange=config.getParameter("kheAA_linkRange",16)
	self.outPartialFillNode=config.getParameter("kheAA_outPartialFillNode")
	self.outCompleteFillNode=config.getParameter("kheAA_outCompleteFillNode")
	
	object.setConfigParameter('description',"^red;Output1:^reset; Partial Fill^red;Output2:^reset; Complete Fill")
end

function update(dt)
	deltatime = (deltatime or 0) + dt;
	if deltatime < 1 then
		return;
	end
	deltatime=0
	findContainer()

	if self.outPartialFillNode or self.outCompleteFillNode then
		self.containerSize=world.containerSize(self.containerId)
		self.containerFill=util.tableSize(world.containerItems(self.containerId) or {})
		
		if self.outPartialFillNode then
			object.setOutputNodeLevel(self.outPartialFillNode,(self.containerFill or 0) > 0)
		end
		if self.outCompleteFillNode then
			object.setOutputNodeLevel(self.outCompleteFillNode,(self.containerFill and self.containerSize) and (self.containerFill==self.containerSize))
		end
	end

end

function findContainer()
	local objectIds = world.objectQuery(entity.position(), self.linkRange, { order = "nearest" })
	for _, objectId in pairs(objectIds) do
		if world.containerSize(objectId) and not world.getObjectParameter(objectId,"notItemStorage",false) then
			self.containerId=objectId
			break
		end
	end 
end

require "/scripts/kheAA/transferUtil.lua"

function init()
	transferUtil.init()
	transferUtil.vars.inContainers={}
	transferUtil.vars.outContainers={}
	transferUtil.vars.containerId=nil
	self.containerPos={0,0}
	self.linkRange=config.getParameter("kheAA_linkRange",16)
	self.outPartialFillNode=config.getParameter("kheAA_outPartialFillNode")
	self.outCompleteFillNode=config.getParameter("kheAA_outCompleteFillNode")

	-- local desc="^blue;Input: ^white;item network^reset;\n^red;Output: ^white;item network^reset;"
	-- if self.outPartialFillNode then
		-- desc=desc.."\n^red;Lower output: ^white;item network^reset;\n^red;Upper outputs: ^white;Partial/Complete Fill^reset;"
	-- end
	-- object.setConfigParameter('description',desc)
end

function update(dt)
	deltatime = (deltatime or 0) + dt;
	if deltatime < 1 then
		return;
	end
	deltatime=0
	findContainer()

	outputnodes()
end

function findContainer()
	transferUtil.zoneAwake(transferUtil.pos2Rect(storage.position,self.linkRange))
	transferUtil.vars.containerId=nil
	self.containerPos=nil
	transferUtil.vars.inContainers={}
	transferUtil.vars.outContainers={}

	local objectIds = world.objectQuery(storage.position, self.linkRange, { order = "nearest" })
	for _, objectId in pairs(objectIds) do
		local tSize=world.containerSize(objectId)
		if tSize and (tSize>0) and not world.getObjectParameter(objectId,"notItemStorage",false) then
			transferUtil.vars.containerId=objectId
			self.containerPos=world.entityPosition(transferUtil.vars.containerId)
			transferUtil.vars.inContainers[transferUtil.vars.containerId]=self.containerPos
			transferUtil.vars.outContainers[transferUtil.vars.containerId]=self.containerPos
			break
		end
	end
end

function outputnodes()

	object.setOutputNodeLevel(transferUtil.vars.outDataNode,not (transferUtil.vars.containerId==nil))
	if transferUtil.vars and transferUtil.vars.containerId and (self.outPartialFillNode or self.outCompleteFillNode) then
		self.containerSize=world.containerSize(transferUtil.vars.containerId)
		self.containerFill=util.tableSize(world.containerItems(transferUtil.vars.containerId) or {})

		if self.outPartialFillNode then
			object.setOutputNodeLevel(self.outPartialFillNode,(self.containerFill or 0) > 0)
		end
		if self.outCompleteFillNode then
			object.setOutputNodeLevel(self.outCompleteFillNode,(self.containerFill and self.containerSize) and (self.containerFill==self.containerSize))
		end
	else
		if self.outPartialFillNode then
			object.setOutputNodeLevel(self.outPartialFillNode,false)
		end
		if self.outCompleteFillNode then
			object.setOutputNodeLevel(self.outCompleteFillNode,false)
		end
	end
end

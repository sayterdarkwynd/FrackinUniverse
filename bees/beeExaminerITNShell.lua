require "/scripts/kheAA/transferUtil.lua"
require "/bees/beeExaminer.lua"
local beeExInit=init
local beeExUpdate=update

function init(...)
	if cLInit then cLInit(...) end
	if beeExInit then beeExInit(...) end
	specialOutDataNode=config.getParameter("productionOutDataNode")
	local desc=config.getParameter("description","")
	object.setConfigParameter('description',desc.."\n^red;Highest Output^reset;: Production Status")
end


function update(dt)
	if beeExUpdate then beeExUpdate(dt) end

	if not transferUtilDeltaTime or (transferUtilDeltaTime > 1) then
		transferUtilDeltaTime=0
		transferUtil.loadSelfContainer()
	else
		transferUtilDeltaTime=transferUtilDeltaTime+dt
	end

	outputnodes()

	if specialOutDataNode then
		object.setOutputNodeLevel(specialOutDataNode,currentlyWorking())
	end
end


function outputnodes()
	object.setOutputNodeLevel(transferUtil.vars.outDataNode,not (transferUtil.vars.containerId==nil))
	if self.outPartialFillNode or self.outCompleteFillNode then
		--self.containerSize=world.containerSize(transferUtil.vars.containerId)
		self.containerItems=world.containerItems(transferUtil.vars.containerId) or {}
		--self.containerFill=util.tableSize(self.containerItems)
		if self.outPartialFillNode then
			object.setOutputNodeLevel(self.outPartialFillNode,self.containerItems[self.inputSlot+1])
		end
		if self.outCompleteFillNode then
			object.setOutputNodeLevel(self.outCompleteFillNode,self.containerItems[self.outputSlot+1])
		end
	end
end

function cLInit()
	transferUtil.init()
	transferUtil.vars.inContainers={}
	transferUtil.vars.outContainers={}
	transferUtil.vars.containerId=nil
	self.containerPos={0,0}
	self.outPartialFillNode=config.getParameter("kheAA_outPartialFillNode")
	self.outCompleteFillNode=config.getParameter("kheAA_outCompleteFillNode")

	local desc="^blue;Input: ^white;item network^reset;\n^red;Output: ^white;item network^reset;"
	if self.outPartialFillNode then
		desc=desc.."\n^red;Lower output: ^white;item network^reset;\n^red;Upper outputs: ^white;Item Input/Output Fill^reset;"
	end
	object.setConfigParameter('description',desc)
end

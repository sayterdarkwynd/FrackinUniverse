require "/objects/kheAA/kheAA_containerLink/kheAA_containerLink.lua"
local cLInit=init
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

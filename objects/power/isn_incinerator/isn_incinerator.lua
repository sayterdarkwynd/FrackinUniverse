require "/scripts/kheAA/transferUtil.lua"
require "/scripts/fu_storageutils.lua"
local deltaTime = 0
	
function init()
	transferUtil.init()
	self.mintick = 1
	object.setInteractive(true)
end

function update(dt)
	if not self.mintick then init() end
	if deltaTime > 1 then
		deltaTime=0
		transferUtil.loadSelfContainer()
	else
		deltaTime=deltaTime+dt
	end
	world.containerTakeAll(entity.id())
end
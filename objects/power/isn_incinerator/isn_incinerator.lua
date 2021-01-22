require "/scripts/kheAA/transferUtil.lua"
require "/scripts/fu_storageutils.lua"

function init()
	self.mintick = 1
	object.setInteractive(true)
end

function update(dt)
	if not self.mintick then init() end
	if not transferUtilDeltaTime or (transferUtilDeltaTime > 1) then
		transferUtilDeltaTime=0
		transferUtil.loadSelfContainer()
	else
		transferUtilDeltaTime=transferUtilDeltaTime+dt
	end
	world.containerTakeAll(entity.id())
end
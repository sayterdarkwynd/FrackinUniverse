require "/scripts/kheAA/excavatorCommon.lua"
local deltatime = 0;

function init()
	excavatorCommon.init()
end

function update(dt)
	transferUtil.loadSelfContainer()
	excavatorCommon.grab(entity.position())
	world.breakObject(entity.id(), true)
end

function anims()

end

function setRunning()

end
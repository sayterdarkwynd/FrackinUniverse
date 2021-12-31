require "/scripts/kheAA/excavatorCommon.lua"

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

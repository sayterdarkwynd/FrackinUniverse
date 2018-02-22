require "/scripts/kheAA/excavatorCommon.lua"
local deltatime = 0;

function init()
	pump=false
	drill=false
	vacuum=true
	powerNode=0
	excavatorCommon.init()
end

function update(dt)
	transferUtil.loadSelfContainer()
	excavatorCommon.grab(entity.position())
	sb.logInfo("%s",storage)
	world.breakObject(entity.id(), true)
end

function anims()

end

function setRunning()

end
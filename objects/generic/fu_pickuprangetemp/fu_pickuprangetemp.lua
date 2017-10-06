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
	excavatorCommon.grab(entity.position(), config.getParameter("range"))
	world.breakObject(world.objectAt(entity.position()), true)
end

function anims()

end

function setRunning()

end
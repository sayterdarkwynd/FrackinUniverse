require "/scripts/kheAA/excavatorCommon.lua"
local deltatime = 0;

function init()
	pump=false
	drill=false
	vacuum=true
	excavatorCommon.init()	
end

function update(dt)
	excavatorCommon.cycle(dt)
end

function anims()

end

function setRunning()

end
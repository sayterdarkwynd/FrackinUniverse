require "/scripts/kheAA/liquidLib.lua"
require "/scripts/kheAA/transferUtil.lua"
local deltatime = 0;

function init()
	transferUtil.init()
	liquidLib.init()
	powerNode=0
	receiveLiquid=true
end

function update(dt)
	deltatime = deltatime + dt;
	if deltatime < 0.05 then
		return
	end
	deltatime = 0;	
	liquidLib.doPump()
end

function die()
	liquidLib.die()
end
require "/scripts/kheAA/liquidLib.lua"
require "/scripts/kheAA/transferUtil.lua"

function init()
	transferUtil.init()
	liquidLib.init()
	receiveLiquid=true
end

function update(dt)
	deltatime = (deltatime or 0) + dt;
	if deltatime < 0.05 then
		return
	end
	deltatime = 0;	
	liquidLib.doPump()
end

function die()
	liquidLib.die()
end
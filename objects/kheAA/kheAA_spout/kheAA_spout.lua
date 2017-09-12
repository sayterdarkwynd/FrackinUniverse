require "/scripts/kheAA/liquidLib.lua"
require "/scripts/kheAA/transferUtil.lua"

function init()
	powerNode=0
	receiveLiquid=true
	transferUtil.init()
	liquidLib.init()
	transferUtil.loadSelfContainer()
end

function update(dt)
	transferUtil.loadSelfContainer()
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
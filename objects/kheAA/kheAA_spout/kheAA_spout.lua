require "/scripts/kheAA/liquidLib.lua"
require "/scripts/kheAA/transferUtil.lua"

function init()
	receiveLiquid=true
	liquidLib.init()
	transferUtil.loadSelfContainer()
end

function update(dt)
	if not transferUtilDeltaTime or (transferUtilDeltaTime > 1) then
		transferUtilDeltaTime=0
		transferUtil.loadSelfContainer()
	else
		transferUtilDeltaTime=transferUtilDeltaTime+dt
	end
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
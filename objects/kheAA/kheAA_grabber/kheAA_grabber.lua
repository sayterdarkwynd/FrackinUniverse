require "/scripts/kheAA/excavatorCommon.lua"

local vacuumRegion

function init()
	excavatorCommon.init()
	vacuumRegion = config.getParameter("vacuumRegion")
end

function update(dt)
	if not transferUtilDeltaTime or (transferUtilDeltaTime > 1) then
		transferUtilDeltaTime=0
		transferUtil.loadSelfContainer()
	else
		transferUtilDeltaTime=transferUtilDeltaTime+dt
	end
	excavatorCommon.cycle(dt)
end

function anims()

end

function setRunning(bState)
	if vacuumRegion then
		physics.setForceEnabled(vacuumRegion, bState)
	end
end

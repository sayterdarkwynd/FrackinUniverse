require "/scripts/kheAA/excavatorCommon.lua"

function init()
	excavatorCommon.init()
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

function setRunning()

end
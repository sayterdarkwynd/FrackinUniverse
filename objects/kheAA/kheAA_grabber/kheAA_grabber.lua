require "/scripts/kheAA/excavatorCommon.lua"

function init()
	excavatorCommon.init()
end

function update(dt)
	transferUtil.loadSelfContainer()
	excavatorCommon.cycle(dt)
end

function anims()

end

function setRunning()

end
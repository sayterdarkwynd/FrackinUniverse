require "/scripts/kheAA/transferUtil.lua"
local deltaTime = 0

function init()
	transferUtil.init()
	object.setInteractive(true)
end

function update(dt)
	deltaTime = deltaTime + dt
	if deltaTime > 1 then
		deltaTime = 0
		transferUtil.loadSelfContainer()
	end
end
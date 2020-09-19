require "/frackinship/scripts/fs_util.lua"

local origInit = init or function() end
local origUpdate = update or function() end

-- Improve this when upgradable ships are added to choosable BYOS

function init()
	origInit()
	pcall(shipRenderInit)
end

function update(dt)
	origUpdate(dt)
	pcall(shipRenderUpdate, dt)
end

function shipRenderInit()
	if world.type == "unknown" and world.getProperty("ship.level", 0) == 0 and not world.getProperty("fu_byos") then
		local speciesShipData = root.assetJson("/universeServer.config")
	end
end

function shipRenderUpdate(dt)
	if fsShipRender and (world.getProperty(ship.level) > 0 or world.getProperty("fu_byos")) then
		localAnimator.clearDrawables()
		fsShipRender = false
	end
end
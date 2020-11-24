require "/scripts/util.lua"
require "/scripts/interp.lua"

local time = 0
local count = false

function init()
	storage.counter = storage.counter or 0
	storage.doCntr = storage.doCntr or false
	storage.craftingData = storage.craftingData or {}
	craftTime = config.getParameter("craftTime", 3)
    animator.setAnimationState("racializer", "idle")
    message.setHandler("doWorkAnim", doWorkAnim)
	message.setHandler("startRacialising", function(_, _, craftingData)
		storage.craftingData = craftingData
		storage.doCntr = true
		object.setConfigParameter("racialising", true)
	end)
end

function doWorkAnim()
    if time == 0 then
        --object.setInteractive(false)
        animator.setAnimationState("racializer", "working")
        count = true
    end
end

function update(dt)
    if(count) then
        time = time + dt
        if time >= 5 then
            animator.setAnimationState("racializer", "idle")
            --object.setInteractive(true)
            time = 0
            count = false
        end
    end

	-- Delay timer for giving new item...
    if storage.doCntr == true then
        storage.counter = storage.counter + dt
    elseif storage.doCntr == false then --reset counter
        storage.counter = 0
    end

    if storage.counter >= craftTime then -- place new item and reset
        world.containerSwapItems(entity.id(), storage.craftingData.itemNew,2)
		storage.craftingData = {}
		object.setConfigParameter("racialising", false)
        --sb.logInfo("New item placed in slot 2")

        storage.doCntr = false
        storage.counter = 0
    end
end

function die()
	if storage.craftingData.itemOld then
		local position = entity.position()
		world.spawnItem(storage.craftingData.itemOld, position)
		world.spawnItem("money", position, storage.craftingData.cost or 0)
		if storage.craftingData.itemPGI then
			world.spawnItem("perfectlygenericitem", position)
		end
	end
end
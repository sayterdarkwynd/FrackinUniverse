require "/scripts/vec2.lua"
require "/scripts/rect.lua"
require "/scripts/kheAA/transferUtil.lua"

function init()
	transferUtil.init()
	sellFactor = config.getParameter("sellFactor")
	surfaceCheckArea = rect.translate(config.getParameter("surfaceCheckArea"), entity.position())
	surfaceCheckInterval = config.getParameter("surfaceCheckInterval")
	surfaceCheckTimer = surfaceCheckInterval
	checkSurface=config.getParameter("checkSurface",true)
	launchDuration = config.getParameter("launchDuration")
	launchTiming = config.getParameter("launchTiming")
	launchPosition = vec2.add(config.getParameter("launchPosition"), entity.position())

	if checkSurface then
		onSurface = surfaceCheck()
	else
		onSurface=true
	end
	if onSurface then
		animator.setAnimationState("shipper", "ready")
	else
		animator.setAnimationState("shipper", "error")
	end
end

function update(dt)
	if checkSurface then
		surfaceCheckTimer = surfaceCheckTimer - dt
		if surfaceCheckTimer <= 0 then
			local onSurface = surfaceCheck()

			if onSurface ~= onSurface then
				onSurface = onSurface
				if onSurface then
					animator.setAnimationState("shipper", "toready")
				else
					animator.setAnimationState("shipper", "toerror")
				end
			end

			surfaceCheckTimer = surfaceCheckInterval
		end
	end

	if launchTimer then
		launchTimer = launchTimer + dt
		if launching and launchTimer >= launchTiming then
			spawnProjectile()
			launching=false
		end
		if launchTimer >= launchDuration then
			launchTimer = nil
			animator.setAnimationState("shipper", "open")
		end
	end

	--object.setInteractive(onSurface and not launchTimer)
end

function surfaceCheck()
	if world.underground(object.position()) then
		return false
	end
	return not world.rectTileCollision(surfaceCheckArea, {"Null", "Block", "Dynamic", "Slippery"})
end

function startLaunch()
	if launching then return end
	local value,count=valueOfContents()
	if count == 0 then return end
	
	launchTimer = 0
	animator.setAnimationState("shipper", "ship")

	--object.setInteractive(false)
	world.containerTakeAll(entity.id())
	world.containerAddItems(entity.id(),{"money",value})
end

function spawnProjectile()
	world.spawnProjectile(
		"cropshipment",
		launchPosition,
		nil,
		{0, 1},
		false,
		{}
	)
end

function valueOfContents()
	local value = 0
	local itemCount=0
	local allItems = world.containerItems(entity.id())
	for item,_ in pairs(allItems) do
		if item.name=="money" then
			value = value + item.count
		else
			local price = root.itemConfig(item).config.price or 0
			value = value + price * item.count
			itemCount = itemCount + 1
		end
	end
	return value,itemCount
end

require "/scripts/vec2.lua"

local origInit = init or function() end
local origUpdate = update or function() end

function init()
	origInit()

	if world.type() == "unknown" then
		local success, err = pcall(fsShipRender)
		if not success then
			sb.logError(tostring(err))
		end
	end
end

function update(dt)
	origUpdate(dt)

	pcall(fsShipRender)

	--if world.getProperty("fu_byos.shipRenderUpdate") then
		--localAnimator.clearDrawables()
		--pcall(fsShipRender)
		--world.setProperty("fu_byos.shipRenderUpdate", false)
	--end
end

function fsShipRender()
	localAnimator.clearDrawables()
	local shipImage = world.getProperty("fu_byos.shipImage")
	if not shipImage and world.getProperty("ship.level", 0) == 0 and not world.getProperty("fu_byos") then
		local shipFile = root.assetJson("/universe_server.config").speciesShips[player.species()][2]
		local shipData = root.assetJson(shipFile)

		-- Get the ship position of [0, 0]
		if string.sub(shipData.blockKey, 1, 1) ~= "/" then
			shipData.blockKey = fsGetAbsolutePath(shipFile, shipData.blockKey)
		end
		if string.sub(shipData.blockImage, 1, 1) ~= "/" then
			shipData.blockImage = fsGetAbsolutePath(shipFile, shipData.blockImage)
		end
		local shipImagePosition = {1024, 1024} --temp

		shipImage = shipData.backgroundOverlays
		for i, imageData in ipairs (shipImage) do
			if string.sub(imageData.image, 1, 1) ~= "/" then
				imageData.image = fsGetAbsolutePath(shipFile, imageData.image)
			end
			imageData.position = vec2.add(shipImagePosition, (imageData.position or {0, 0}))
		end
		world.setProperty("fu_byos.shipImage", shipImage)
	end
	shipImage = shipImage or {}
	for _, imageData in ipairs (shipImage) do
		localAnimator.addDrawable({
			image = imageData.image,
			position = vec2.sub(imageData.position, entity.position()),
			fullbright = imageData.fullbright or false
		}, "BackgroundTile-1")
	end
	--sb.logInfo(sb.printJson(shipImage))
end

function fsGetAbsolutePath(shipFile, relativeFile)
	local reversedFile = string.reverse(shipFile)
	local snipLocation = string.find(reversedFile, "/")
	local shipFileGsub = string.sub(shipFile, -snipLocation + 1)
	local absoluteFile = shipFile:gsub(shipFileGsub, relativeFile)
	return absoluteFile
end
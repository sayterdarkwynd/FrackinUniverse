require "/scripts/vec2.lua"

function init()
	-- Currently gets the image every init() for testing purposes, might not change this since it disappears after you select your ship
	local shipRace = world.getProperty("frackinship.race", "apex")
	local shipsConfig = root.assetJson("/universe_server.config").speciesShips[shipRace]
	if shipsConfig then
		local shipConfigPath = shipsConfig[2]
		local shipConfig = root.assetJson(shipConfigPath)
		local reversedFile = string.reverse(shipConfigPath)
		local snipLocation = string.find(reversedFile, "/")
		local shipPathGsub = string.sub(shipConfigPath, -snipLocation + 1)
		for i, overlay in ipairs (shipConfig.backgroundOverlays) do
			if string.sub(overlay.image, 1, 1) ~= "/" then
				shipConfig.backgroundOverlays[i].image = shipConfigPath:gsub(shipPathGsub, overlay.image)
			end
		end
		local blockKeyPath = shipConfig.blockKey
		if string.sub(blockKeyPath, 1, 1) ~= "/" then
			blockKeyPath = shipConfigPath:gsub(shipPathGsub, blockKeyPath)
		end
		local blockKey = root.assetJson(blockKeyPath)
		if string.sub(shipConfig.blockImage, 1, 1) ~= "/" then
			shipConfig.blockImage = shipConfigPath:gsub(shipPathGsub, shipConfig.blockImage)
		end
		-- Code for getting [0, 0] position of the ship background
		local blockImage = config.getParameter("blockImageBase")
		local blockImageSize = root.imageSize(shipConfig.blockImage)
		-- Change the base to a square that can fit the block image
		blockImage = blockImage .. "?scalenearest=" .. tostring(math.max(blockImageSize[1], blockImageSize[2]))
		-- Change the base image square to the same size as the block image
		blockImage = blockImage .. "?crop=0;0;" .. tostring(blockImageSize[1]) .. ";" .. tostring(blockImageSize[2])
		-- Add the block image to the base image
		blockImage = blockImage .. "?blendmult=" .. shipConfig.blockImage
		-- Make it so that block pixel is one block
		blockImage = blockImage .. "?scalenearest=8"
		-- Remove all the blocks except the player spawn one from the block image
		blockImage = blockImage .. "?replace"
		for _, blockData in ipairs (blockKey) do
			if not blockData.anchor then
				local hexColour = ""
				local i = 1
				while i <= 3 do
					hexColour = hexColour .. string.format("%02x", blockData.value[i])
					i = i + 1
				end
				hexColour = hexColour .. string.format("%02x", math.ceil((blockData.value[4] or 255) / 2))
				blockImage = blockImage .. ";" .. hexColour .. "=0000"
			end
		end
		-- Get the base ship background image offset from the created block image
		local baseImageOffset = root.imageSpaces(blockImage, {0.69, 0.69}, 0.3)	-- Not sure why but non-whole numbers between 0.5 and 1 seem to have 1 space at 0.3 spacescan, might need to investigate this more later, but this works for now
		object.setConfigParameter("backgroundOverlays", shipConfig.backgroundOverlays)
		object.setConfigParameter("baseImageOffset", baseImageOffset[1])
	end
end

function update(dt)
	if world.getProperty("ship.level", 1) ~= 0 or world.getProperty("fu_byos") then
		object.smash()
	end
end
function getShipImage(file)
	if file then
		local shipConfig = root.assetJson(file)
		local reversedFile = string.reverse(file)
		local snipLocation = string.find(reversedFile, "/")
		local shipImagePathGsub = string.sub(file, -snipLocation + 1)
		local shipImage = shipConfig.backgroundOverlays[1].image
		if not string.find(shipImage, "/") then
			shipImage = file:gsub(shipImagePathGsub, shipImage)
		end
		return shipImage
	end
end
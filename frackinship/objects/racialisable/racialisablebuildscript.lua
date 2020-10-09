require "/scripts/util.lua"

function build(directory, config, parameters, level, seed)
	-- skip building the item if it's already built or the object doesn't have it's racialse type set
	if not parameters.built and config.racialiseType then
		parameters.racialiseData = parameters.racialiseData or config.racialiseData or {race = "Human", object = "human" .. config.racialiseType}
		local item = root.itemConfig(parameters.racialiseData.object)
		if item then
			parameters = util.mergeTable(parameters, item.config)
			parameters = util.mergeTable(parameters, item.parameters or {})
			parameters.itemName = nil
			parameters.objectName = nil
			parameters.shortdescription = config.shortdescription .. " (" .. parameters.racialiseData.race .. ")"
			parameters.inventoryIcon = getAbsolutePath(parameters.inventoryIcon, item.directory)
			for part, image in pairs (parameters.animationParts or {}) do
				parameters.animationParts[part] = getAbsolutePath(image, item.directory)
			end
			parameters.placementImage, parameters.placementImagePosition = getPlacementImage(parameters.orientations, item.directory, parameters.racialiseData.positionOverride)
			
			parameters.built = true
		else
			sb.logError("Couldn't find info for object " .. parameters.racialiseData.object .. " skiping building racialisable object!")
		end
	end

	return config, parameters
end

function getAbsolutePath(path, directory)
	if string.sub(path, 1, 1) ~= "/" then
		path = directory .. path
	end
	return path
end

-- Maybe redo at some stage (too lazy to do it atm)
function getPlacementImage(objectOrientations, objectDirectory, positionOverride)
	local objectOrientation = objectOrientations[1]
	local objectImage
	if objectOrientation.imageLayers then
		objectImage = objectOrientation.imageLayers[1].image
	else
		objectImage = objectOrientation.dualImage or objectOrientation.image
	end
	local newPlacementImage
	if string.sub(objectImage, 1, 1) ~= "/" then
		newPlacementImage = objectDirectory .. objectImage
	else
		newPlacementImage = objectImage
	end

	local newPlacementImagePosition = objectOrientation.imagePosition
	if positionOverride then
		newPlacementImagePosition = positionOverride
	end
	return newPlacementImage:gsub("<frame>", 0):gsub("<color>", "default"):gsub("<key>", 1), newPlacementImagePosition
end
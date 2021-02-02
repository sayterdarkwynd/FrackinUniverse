local fsPopulateMiscList = populateMiscList or function() end
local fsMiscSelectedSafe = miscSelectedSafe or function() end
local fsDefaultAI = defaultAI or function() end

function populateMiscList()
	GUI.frackinship.sailSelect = false
	
	fsPopulateMiscList()
end

function miscSelectedSafe()
	if GUI.frackinship.sailSelect then
		local selected = widget.getListSelected("root.miscList")
		if selected then
			local listData = widget.getData("root.miscList."..selected)
			if listData then
				world.setProperty("frackinship.sailRace", listData.race)
				loadFrackinShipSail(listData.race)
			end
		end
	else
		fsMiscSelectedSafe()
	end
end

function defaultAI(type)
	fsDefaultAI(type)
	
	loadFrackinShipSail()
end

function loadFrackinShipSail(race)
	local frackinshipSailRace = race or world.getProperty("frackinship.sailRace")
	if frackinshipSailRace then
		local sailList = root.assetJson("/ai/ai.config").species or {}
		if sailList[frackinshipSailRace] then
			GUI.talker.imagePath = (sailList[frackinshipSailRace].aiFrames or "apexAi.png")
			GUI.static.image = "/ai/"..(sailList[frackinshipSailRace].staticFrames or "staticApex.png")
		end
	end
end
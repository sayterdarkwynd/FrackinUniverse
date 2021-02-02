require "/frackinship/scripts/frackinshiputil.lua"

function changeSailImage()
	widget.clearListItems("root.miscList")
	GUI.frackinship.sailSelect = true
	local sailList = root.assetJson("/ai/ai.config").species or {}
	local races = frackinship.getRaceList()
	for _, race in pairs (races) do
		local succeded, raceData = pcall(root.assetJson, "/species/" .. race .. ".species")
		if succeded and raceData and raceData.charCreationTooltip then
			sailList[race].name = raceData.charCreationTooltip.title
		end
		local listItem = "root.miscList."..widget.addListItem("root.miscList")
		widget.setText(listItem..".name", sailList[race].name)
		widget.setImage(listItem..".icon", "/ai/" .. sailList[race].aiFrames .. ":idle?scalenearest=0.2")
		widget.setData(listItem, {race = race})
	end
end
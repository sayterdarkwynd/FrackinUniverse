require "/scripts/util.lua"
require "/scripts/pathutil.lua"
require "/interface/objectcrafting/fu_racialiser/fu_racialiser.lua"
require "/scripts/textTyper.lua"

function init()
	textData = {}
	textUpdateDelay = config.getParameter("textUpdateDelay")
	chatterSound = config.getParameter("chatterSound")
	aiFaceCanvas = widget.bindCanvas("aiFaceCanvas")
	aiImage = {image = config.getParameter("aiImage")}
	aiImage.frames = config.getParameter("aiFrames") - 1
	aiImage.updateTime = config.getParameter("aiUpdateTime")
	aiImage.currentFrame = 0
	scanlines = {image = config.getParameter("scanlinesImage")}
	scanlines.frames = config.getParameter("scanlinesFrames") - 1
	scanlines.updateTime = config.getParameter("scanlinesUpdateTime")
	scanlines.currentFrame = 0
	static = {image = config.getParameter("staticImage")}
	static.frames = config.getParameter("staticFrames") - 1
	static.updateTime = config.getParameter("staticUpdateTime")
	static.currentFrame = 0
	updateAiImage()
	writerInit(textData, config.getParameter("shipStatus"))
	widget.setButtonEnabled("showMissions", false)
	widget.setButtonEnabled("showCrew", false)
	pane.playSound(chatterSound, -1)
end

function update(dt)
	if not textData.isFinished then
		if textUpdateDelay <= 0 then
			writerUpdate(textData, "shipStatusText")
			textUpdateDelay = config.getParameter("textUpdateDelay")
		else
			textUpdateDelay = textUpdateDelay - 1
		end
		if aiImage.updateTime <= 0 then
			aiImage.currentFrame = updateFrame(aiImage)
			aiImage.updateTime = config.getParameter("aiUpdateTime")
		else
			aiImage.updateTime = aiImage.updateTime - dt
		end
	else
		pane.stopAllSounds(chatterSound)
		if aiImage.currentFrame ~= aiImage.frames and aiImage.updateTime <= 0 then
			aiImage.currentFrame = updateFrame(aiImage)
			aiImage.updateTime = config.getParameter("aiUpdateTime")
		else
			aiImage.updateTime = aiImage.updateTime - dt
		end
		widget.setButtonEnabled("showMissions", true)
		widget.setButtonEnabled("showCrew", true)
	end
	if scanlines.updateTime <= 0 then
		scanlines.currentFrame = updateFrame(scanlines)
		scanlines.updateTime = config.getParameter("scanlinesUpdateTime")
	else
		scanlines.updateTime = scanlines.updateTime - dt
	end
	if static.updateTime <= 0 then
		static.currentFrame = updateFrame(static)
		static.updateTime = config.getParameter("staticUpdateTime")
	else
		static.updateTime = static.updateTime - dt
	end
	updateAiImage()
end

function updateFrame(imageTable)
	imageTable.currentFrame = imageTable.currentFrame + 1
	if imageTable.currentFrame > imageTable.frames then
		imageTable.currentFrame = 0
	end
	return imageTable.currentFrame
end

function updateAiImage()
	aiFaceCanvas:clear()
	aiFaceCanvas:drawImage(aiImage.image:gsub("<frame>", aiImage.currentFrame), vec2.div(aiFaceCanvas:size(), 2), 2, nil, true)
	aiFaceCanvas:drawImage(scanlines.image:gsub("<frame>", scanlines.currentFrame), vec2.div(aiFaceCanvas:size(), 2), 1, nil, true)
	aiFaceCanvas:drawImage(static.image:gsub("<frame>", static.currentFrame), vec2.div(aiFaceCanvas:size(), 2), 1, nil, true)
end

function uninit()
	pane.stopAllSounds(chatterSound)
end

function byos()
	player.startQuest("fu_byos")
	player.startQuest("fu_shipupgrades")
	for _, recipe in pairs (root.assetJson("/interface/ai/fu_byosrecipes.config")) do
		player.giveBlueprint(recipe)
	end
	world.sendEntityMessage("bootup", "byos", player.species())
end

function racial()
	local teleporters = world.entityQuery(world.entityPosition(player.id()), 100, {includedTypes = {"object"}})
    teleporters = util.filter(teleporters, function(entityId)
		if string.find(world.entityName(entityId), "teleporterTier0") then
			return true
		end
    end)
    if #teleporters > 0 then
		player.lounge(teleporters[1])
    end
	race = player.species()
	count = racialiserBootUp()
	parameters = getBYOSParameters("techstation", true, _)
	player.giveItem({name = "fu_byostechstationdeco", count = 1, parameters = parameters})
	player.startQuest("fu_shipupgrades")
	player.upgradeShip({shipLevel = 1})
end

function racialiserBootUp()
	raceInfo = root.assetJson("/interface/objectcrafting/fu_racialiser/fu_raceinfo.config")
	for num, info in pairs (raceInfo) do
		if info.race == race then
			return num
		end
	end
	return 1
end
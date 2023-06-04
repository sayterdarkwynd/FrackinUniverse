require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/zb/zb_textTyper.lua"

function init()
	textData = {}
	textUpdateDelay = config.getParameter("textUpdateDelay")
	chatterSound = config.getParameter("chatterSound")
	aiFaceCanvas = widget.bindCanvas("aiFaceCanvas")
	aiImage = {image = config.getParameter("aiImage")}
	aiImageFinished = {image = config.getParameter("aiImageFinished")}
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
	textTyper.init(textData, config.getParameter("shipStatus"))
	pane.playSound(chatterSound, -1)
end

function update(dt)
	if not textData.isFinished then
		if textUpdateDelay <= 0 then
			textTyper.update(textData, "root.text")
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
	if not textData.isFinished then
		aiFaceCanvas:drawImage(aiImage.image:gsub("<frame>", aiImage.currentFrame), vec2.div(aiFaceCanvas:size(), 2), 2, nil, true)
	else
		aiFaceCanvas:drawImage(aiImageFinished.image, vec2.div(aiFaceCanvas:size(), 2), 2, nil, true)
	end
	aiFaceCanvas:drawImage(scanlines.image:gsub("<frame>", scanlines.currentFrame), vec2.div(aiFaceCanvas:size(), 2), 1, nil, true)
	aiFaceCanvas:drawImage(static.image:gsub("<frame>", static.currentFrame), vec2.div(aiFaceCanvas:size(), 2), 1, nil, true)
end

function uninit()
	pane.stopAllSounds(chatterSound)
end

function buttonMain()

end
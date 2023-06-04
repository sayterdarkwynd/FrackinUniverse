function init()
	self.sounds = config.getParameter("sounds")
	self.flickerTime = config.getParameter("disabledFlickerTime")
	self.flicker = config.getParameter("disabledFlicker")
	self.color = config.getParameter("disabledColor")

	timer = 0

	pane.playSound(self.sounds.open)
	widget.setFontColor("disabledLabel", self.color)

	player.lounge(pane.sourceEntity())
end

function dismissed()
	for _,sound in pairs(self.sounds) do
		pane.stopAllSounds(sound)
	end
end

function update(dt)
	if timer <= 0 then
		self.color[4] = (self.flicker[1] + (math.random() * (self.flicker[2] - self.flicker[1]))) * 255
		timer = self.flickerTime
		widget.setFontColor("disabledLabel", self.color)
    end
    timer = timer - dt
end
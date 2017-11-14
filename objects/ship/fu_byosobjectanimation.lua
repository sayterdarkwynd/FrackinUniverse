-- Based on Cat Face's customisable S.A.I.L mod code
require "/scripts/vec2.lua"
require "/scripts/util.lua"

function init()
	self.animationTimer = 0
	self.position = entity.position()
	self.imageconfig = config.getParameter("imageConfig") or config.getParameter("defaultImageConfig")
	if self.imageconfig[1].imageLayers then --Avali teleporter issues again
		self.image = self.imageconfig[1].imageLayers[1].image
	else
		self.image = self.imageconfig[1].dualImage or self.imageconfig[1].image
	end
	self.imageLayers = self.imageconfig[1].imageLayers
	imageSize = root.imageSize(self.image:gsub("<frame>", 1):gsub("<color>", "default"):gsub("<key>", 1))
	imageOffset = self.imageconfig[1].imagePosition
	self.imagePosition = vec2.sub(self.position, vec2.div(vec2.sub(vec2.div(imageSize, 2), vec2.add(imageSize, imageOffset)), 8))
	self.direction = objectAnimator.direction()
	self.objectType = config.getParameter("racialiserType")
	self.doorState = config.getParameter("doorState")
end

function update()
	localAnimator.clearDrawables()
	if self.imageconfig then
		dt = script.updateDt()
		
		if self.imageconfig[1].animationCycle and self.imageconfig[1].frames then
			frame = math.floor((self.animationTimer / self.imageconfig[1].animationCycle) * self.imageconfig[1].frames)
			if self.animationTimer == 0 then frame = 0 end

			self.animationTimer = self.animationTimer + dt
			if self.animationTimer > self.imageconfig[1].animationCycle then
				self.animationTimer = 0
			end
		else
			frame = 0
		end
		--sb.logInfo(self.objectType)
		if self.objectType ~= "shipdoor" and self.objectType ~= "shiphatch" then
			if self.imageLayers then
				for num,_ in pairs (self.imageLayers) do
					if self.direction == 1 then
						localAnimator.addDrawable({
						image = self.imageLayers[num].image:gsub("<frame>", frame):gsub("<color>", "default"):gsub("<key>", frame),
						position = self.imagePosition,
						fullbright = self.imageLayers[num].fullbright
						}, "object+" .. num - 1)
					else
						localAnimator.addDrawable({
						image = self.imageLayers[num].image:gsub("<frame>", frame):gsub("<color>", "default"):gsub("<key>", frame) .. "?flipx",
						position = self.imagePosition,
						fullbright = self.imageLayers[num].fullbright
						}, "object+" .. num - 1)
					end
				end
			else
				if self.direction == 1 then
					localAnimator.addDrawable({
					image = self.image:gsub("<frame>", frame):gsub("<color>", "default"):gsub("<key>", frame),
					position = self.imagePosition
					}, "object")
				else
					localAnimator.addDrawable({
					image = self.image:gsub("<frame>", frame):gsub("<color>", "default"):gsub("<key>", frame) .. "?flipx",
					position = self.imagePosition
					}, "object")
				end
			end
		else
			if self.doorState ~= config.getParameter("doorState") then
				self.doorState = config.getParameter("doorState")
				frame = 1
			else
				frame = 2
			end
			if self.direction == 1 then
				localAnimator.addDrawable({
				image = self.image:gsub("default", self.doorState .. "Right." .. frame),
				position = self.imagePosition
				}, "object+5")
			else
				localAnimator.addDrawable({
				image = self.image:gsub("default", self.doorState .. "Left." .. frame) .. "?flipx",
				position = self.imagePosition
				}, "object+5")
			end
		end
	end
end
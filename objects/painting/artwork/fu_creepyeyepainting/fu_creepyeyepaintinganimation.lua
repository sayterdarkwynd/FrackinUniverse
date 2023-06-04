require "/scripts/vec2.lua"
require "/scripts/util.lua"

function init()
	self = config.getParameter("self")
	self.position = entity.position()
	local imageSize = root.imageSize(self.image:gsub("<frame>", "default"))
	local imageOffset = config.getParameter("orientations")[1].imagePosition
	self.imagePosition = vec2.sub(self.position, vec2.div(vec2.sub(vec2.div(imageSize, 2), vec2.add(imageSize, imageOffset)), 8))
	self.renderImage = self.image:gsub("<frame>", "default")
	self.state = "off"
	self.counter = 0
	script.setUpdateDelta(config.getParameter("updateDelta", 1))
end

function update()
	localAnimator.clearDrawables()
	local lightLevel = math.min(world.lightLevel(self.position),1.0)
	if self.state == "turningOn" or self.state == "turningOff" then
		--Makes it work
	elseif lightLevel < self.maxLight then
		if self.state == "tracking" then
			trackPlayer()
		else
			self.state = "turningOn"
		end
	else
		if self.state == "off" then
			self.renderImage = self.image:gsub("<frame>", "off")
		else
			self.state = "turningOff"
		end
	end
	if self.state == "turningOn" then
		turnOn()
	elseif self.state == "turningOff" then
		turnOff()
	end
	localAnimator.addDrawable({
		image = self.renderImage,
		position = self.imagePosition
	}, "object+1")
end

function trackPlayer()
	local players = world.playerQuery(self.position, self.maxRenderDistance)
	for _, player in ipairs(players) do
		local promise = world.sendEntityMessage(player, "fu_key", "Lone Zin")
		if promise:finished() then
			local distance = world.magnitude(self.position, world.entityPosition(player))
			local angle = vec2.angle(world.distance(self.position, world.entityPosition(player))) * (180 / math.pi)
			if distance > self.minLookDistance and distance < self.maxLookDistance then
				for _, direction in ipairs(self.directions or {}) do
					if angle >= direction[2] and angle <= direction[3] then
						self.renderImage = self.image:gsub("<frame>", direction[1])
						break
					end
				end
			else
				self.renderImage = self.image:gsub("<frame>", "on")
			end
		end
	end
end

function turnOn()
	if self.counter < self.turnOnFrames then
		self.counter = self.counter + 1
		self.renderImage = self.image:gsub("<frame>", "turnOn."..self.counter)
	else
		self.renderImage = self.image:gsub("<frame>", "on")
		self.state = "tracking"
		self.counter = 0
	end
end

function turnOff()
	if self.counter < self.turnOnFrames then
		self.counter = self.counter + 1
		self.renderImage = self.image:gsub("<frame>", "turnOff."..self.counter)
	else
		self.renderImage = self.image:gsub("<frame>", "off")
		self.state = "off"
		self.counter = 0
	end
end
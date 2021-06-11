require "/scripts/vec2.lua"
require "/scripts/util.lua"


scannerLib3={}
scannerLib3.colors = {
	coal = {40, 40, 40, 255},
	copper = {80, 80, 40, 255},
	silver = {200, 200, 230, 255},
	gold = {200, 180, 30, 255},
	iron = {160, 160, 160, 255},
	tungsten = {120, 120, 120, 255},
	titanium = {255, 255, 255, 255},
	durasteel = {90, 90, 200, 255},
	aegisalt = {200, 255, 50, 255},
	violium = {200, 70, 255, 255},
	ferozium = {50, 230, 230, 255},
	solarium = {255, 255, 0, 255},
	diamond = {0, 0, 255, 255},
	erchius = {235, 178, 247, 255},

	lead = {102, 102, 102, 255},
	magnesium = {120, 125, 117, 255},
	mascagnite = {185, 165, 148, 255},
	sulphur = {165, 159, 106, 255},
	lunariore = {77, 222, 77, 255},

	uranium = {0, 255, 0, 255},
	plutonium = {222, 0, 222, 255},
	neptunium = {173, 129, 192, 255},
	thorium = {128, 172, 193, 255},
	moonstone = {135, 170, 138, 255},
	zerchesium = {180, 30, 80, 205},
	protocite = {0, 222, 93, 255},
	penumbrite = {185, 0, 180, 255},
	trianglium = {185, 185, 0, 255},

	prisilite = {222, 122, 222, 255},
	quietus = {200, 88, 0, 255},
	fublooddiamond = {225, 0, 0, 255},
	corruption = {0, 222, 210, 255},
	effigium = {222, 222, 222, 255},
	isogen = {59, 96, 255, 205},
	xithricite = {106, 157, 232, 205},
	pyreite = {230, 124, 0, 205},

	none = {120, 160, 120, 50},
	empty = {30, 30, 255, 255},
	solid = {120, 120, 160, 50}
}

scannerLib3.images = {--planning to use image copies of tiles instead, somehow

}

function init()
	self.pingTimer = 0
	self.cooldownTimer = 0
	self.detectConfig = config.getParameter("pingDetectConfig")
	self.pingOuterRadius=0
	self.pingInnerRadius=0
	script.setUpdateDelta(self.detectConfig and 6 or 0)
end

function update(dt)
	if dt == nil then
		dt=script.updateDt()
	end
	if dt==nil then
		return
	end


	localAnimator.clearDrawables()
	if self.pingTimer == 0 and self.cooldownTimer == 0 then
		self.pingTimer = self.detectConfig.pingDuration
		self.cooldownTimer=self.detectConfig.pingCooldown
		self.pingLocation=vec2.floor(entity.position())
	elseif self.pingTimer > 0 then
		self.pingTimer = math.max(self.pingTimer - dt, 0)

		if self.pingTimer == 0 then
			self.pingLocation=nil
		else
			local radius = (self.detectConfig.pingRange + self.detectConfig.pingBandWidth) * ((self.detectConfig.pingDuration - self.pingTimer) / self.detectConfig.pingDuration) - self.detectConfig.pingBandWidth
			self.pingOuterRadius=radius + self.detectConfig.pingBandWidth
			self.pingInnerRadius= math.max(radius, 0)
		end

		if self.pingLocation then

			self.colorCache = {}
			if self.detectConfig.types then
				for _,t in pairs(self.detectConfig.types) do
					self.colorCache[t]={}
				end
			elseif self.detectConfig.type then
				self.colorCache[self.detectConfig.type]={}
			end

			local fadeDistance = self.pingOuterRadius - self.pingInnerRadius
			local searchRange = math.floor(math.min(self.detectConfig.pingRange, self.pingOuterRadius))
			local srsq = searchRange ^ 2
			local irsq = self.pingInnerRadius ^ 2

			for x = -searchRange, searchRange do
				for y = -searchRange, searchRange do
					local distSquared = x ^ 2 + y ^ 2
					if distSquared <= srsq and distSquared >= irsq then
						local position = {x + self.pingLocation[1], y + self.pingLocation[2]}
						local cacheKey = position[1]..","..position[2]

						for sType,_ in pairs(self.colorCache) do
							if not self.colorCache[sType][cacheKey] then
								if sType == "cave" then
									if world.pointTileCollision(position) then
										self.colorCache[sType][cacheKey] = scannerLib3.colors.solid
									else
										self.colorCache[sType][cacheKey] = scannerLib3.colors.empty
									end
								elseif sType == "ore" then
									local oreMod
									if world.pointTileCollision(position) then
										oreMod = world.mod(position, "foreground")
									else
										oreMod = world.mod(position, "background")
									end

									if scannerLib3.colors[oreMod] then
										self.colorCache[sType][cacheKey] = scannerLib3.colors[oreMod]
									else
										self.colorCache[sType][cacheKey] = scannerLib3.colors.none
									end
								end
							end
						end

						for sType,_ in pairs(self.colorCache) do
							local color = copy(self.colorCache[sType][cacheKey])

							local dist = math.sqrt(distSquared)
							local fadeFactor = 2 * math.min(dist - self.pingInnerRadius,self.pingOuterRadius - dist, searchRange - dist) / fadeDistance
							color[4] = color[4] * fadeFactor

							local variant = math.random(1, self.detectConfig.variants)
							localAnimator.addDrawable(
								{
									image = self.detectConfig.image:gsub("<variant>", variant),
									fullbright = true,
									position = position,
									centered = false,
									color = color
								},
								"overlay"
							)
						end
					end
				end
			end
		end
	elseif self.cooldownTimer > 0 then
		self.cooldownTimer = math.max(self.cooldownTimer - dt, 0)
	end
end
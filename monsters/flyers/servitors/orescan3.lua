require "/scripts/vec2.lua"
require "/scripts/util.lua"
require "/scripts/scannerLib3.lua"

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
							local fadeFactor = 2 * math.min(dist - self.pingInnerRadius, math.min(self.pingOuterRadius - dist, searchRange - dist)) / fadeDistance
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
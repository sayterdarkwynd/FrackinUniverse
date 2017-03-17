require "/scripts/vec2.lua"
require "/scripts/util.lua"

function init()
	self.pingRange = config.getParameter("pingRange",25)
	self.pingBandWidth = config.getParameter("pingBandWidth",10)
	self.pingDuration = config.getParameter("pingDuration",2.5)
	self.pingCooldown = config.getParameter("pingCooldown",0.0)
	self.pingTimer = 0
	self.cooldownTimer = 0
	self.detectConfig = config.getParameter("pingdetectConfig")
end

function update(dt)
	if self.pingTimer == 0 and self.cooldownTimer == 0 then
		self.pingTimer = self.pingDuration
		self.cooldownTimer=self.pingCooldown
		self.pingLocation=vec2.floor(vec2.add(mcontroller.position(), {2.0/2.0,4.0/2.0}))
		animator.playSound("ping")
	elseif self.pingTimer > 0 then
		self.pingTimer = math.max(self.pingTimer - dt, 0)
		if self.pingTimer == 0 then
			self.pingLocation=nil
		else
			local radius = (self.pingRange + self.pingBandWidth) * ((self.pingDuration - self.pingTimer) / self.pingDuration) - self.pingBandWidth
			self.pingself.pingOuterRadius=radius + self.pingBandWidth
			self.pingself.pingInnerRadius= math.max(radius, 0)
		end
	elseif self.cooldownTimer > 0 then
		self.cooldownTimer = math.max(self.cooldownTimer - dt, 0)
	end
	sb.logInfo("%s",_ENV)
	animate()
end


function animate()
	self.drawables={}
	localAnimator.clearDrawables()
	if self.pingLocation then
		self.colorCache = {}
		local fadeDistance = self.pingOuterRadius - self.pingInnerRadius

		local searchRange = math.min(self.detectConfig.maxRange, self.pingOuterRadius)
		local srsq = searchRange ^ 2
		local irsq = self.pingInnerRadius ^ 2
		local new, cached = 0, 0
		for x = -searchRange, searchRange do
			for y = -searchRange, searchRange do
			local distSquared = x ^ 2 + y ^ 2
				if distSquared <= srsq and distSquared >= irsq then
				local position = {x + self.pingLocation[1], y + self.pingLocation[2]}

				local cacheKey = position[1]..","..position[2]
				if not self.colorCache[cacheKey] then
					new = new + 1
					if self.detectConfig.type == "cave" then
						if world.pointTileCollision(position) then
							self.colorCache[cacheKey] = self.detectConfig.colors.solid
						else
							self.colorCache[cacheKey] = self.detectConfig.colors.empty
						end
					elseif self.detectConfig.type == "ore" then
						local oreMod
						if world.pointTileCollision(position) then
							oreMod = world.mod(position, "foreground")
						else
							oreMod = world.mod(position, "background")
						end

						if self.detectConfig.colors[oreMod] then
							self.colorCache[cacheKey] = self.detectConfig.colors[oreMod]
						else
							self.colorCache[cacheKey] = self.detectConfig.colors.none
						end
					end
				else
					cached = cached + 1
				end

				local color = copy(self.colorCache[cacheKey])

				local dist = math.sqrt(distSquared)
				local fadeFactor = 2 * math.min(dist - self.pingInnerRadius, math.min(self.pingOuterRadius - dist, searchRange - dist)) / fadeDistance
				color[4] = color[4] * fadeFactor

				local variant = math.random(1, self.detectConfig.variants)
				table.insert(self.drawables,{{
					image = self.detectConfig.image:gsub("<variant>", variant),
					fullbright = true,
					position = position,
					centered = false,
					color = color
				}, "overlay"})
				end
			end
		end
		for _,d in pairs(self.drawables)do
			localAnimator.addDrawable(d[1],d[2])
		end
	end
end
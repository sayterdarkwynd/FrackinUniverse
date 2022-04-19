require("/scripts/vec2.lua")
require("/scripts/FRHelper.lua")
require ("/items/active/weapons/masteries.lua")--this will load "/items/active/tagCaching.lua"

local FR_old_init = init
local FR_old_update = update
local FR_old_uninit = uninit

function init(...)
	if FR_old_init then
		FR_old_init(...)
	end
	self.lastYPosition = 0
	self.lastYVelocity = 0
	self.fallDistance = 0
	message.setHandler("FR_getSpecies", function() return self.species end)
	masteries.update(0)
end

function update(dt)
	if FR_old_update then
		FR_old_update(dt)
	end
	self.isNpc=world.isNpc(entity.id())
	status.addEphemeralEffect("fucheatdeathhandler",3)
	local enabled = status.statusProperty("fr_enabled")
	local race = enabled and status.statusProperty("fr_race") or "_default"
	if enabled == nil then
		status.setStatusProperty("fr_enabled", true)
		race = world.entitySpecies(entity.id())
		status.setStatusProperty("fr_race", race)
	end
	if self.isNpc then
		if not fuPersistentEffectRecorder then
			require ("/scripts/fuPersistentEffectRecorder.lua")
			fuPersistentEffectRecorder.init()
		end
		fuPersistentEffectRecorder.update(dt)
		local overrideval=world.getProperty("frnpcoverride")
		if (overrideval ~= nil) and enabled ~= overrideval then
			status.setStatusProperty("fr_enabled", overrideval)
		end
	end

	if not self.helper or not self.species or self.species ~= race then
		-- If we've done this before, then we're switching races and need to clear these
		if self.helper then
			for _, eff in pairs(self.helper.speciesConfig.special or {}) do
				status.removeEphemeralEffect(eff)
			end
			status.clearPersistentEffects("FR_special")
			self.helper:clearPersistent()
		end

		self.species = race
		self.helper = FRHelper:new(self.species, world.entityGender(entity.id()))

		-- Script setup
		for map,path in pairs(self.helper.frconfig.scriptMaps) do
			if self.helper.speciesConfig[map] then
				self.helper:loadScript({script=path, args=self.helper.speciesConfig[map]})
			end
		end
		for _,script in pairs(self.helper.speciesConfig.scripts or {}) do
			self.helper:loadScript(script)
		end

		-- Apply the persistent effect
		local derp=copy(self.helper.speciesConfig.stats or {})
		--sb.logInfo("FR_racialStats pre: %s",derp)
		for _,statSet in pairs(derp) do
			if (statSet.stat=="maxEnergy") or (statSet.stat=="maxHealth") then
				if statSet.amount then statSet.amount=util.clamp(statSet.amount,-50,50)
				elseif statSet.effectiveMultiplier then statSet.effectiveMultiplier=util.clamp(statSet.effectiveMultiplier,0.5,1.5)
				elseif statSet.baseMultiplier then statSet.baseMultiplier=util.clamp(statSet.baseMultiplier,0.5,1.5)
				end
			elseif (statSet.stat=="powerMultiplier") then
				if statSet.amount then statSet.amount=util.clamp(statSet.amount,-0.5,0.5)--they should be using basemult or effectivemult.
				elseif statSet.effectiveMultiplier then statSet.effectiveMultiplier=util.clamp(statSet.effectiveMultiplier,0.7,1.3)
				elseif statSet.baseMultiplier then statSet.baseMultiplier=util.clamp(statSet.baseMultiplier,0.5,1.5)
				end
			elseif (statSet.stat=="protection") then
				if statSet.amount then statSet.amount=util.clamp(statSet.amount,-25,25)
				elseif statSet.effectiveMultiplier then statSet.effectiveMultiplier=util.clamp(statSet.effectiveMultiplier,0.7,1.3)
				--elseif statSet.baseMultiplier then statSet.baseMultiplier=util.clamp(statSet.baseMultiplier,0.5,1.5)--has no effect. base is 0.
				end
			elseif string.find(statSet.stat,"Resistance") then
				if statSet.amount then statSet.amount=util.clamp(statSet.amount,-1.0,1.0)
				elseif statSet.effectiveMultiplier then statSet.effectiveMultiplier=util.clamp(statSet.effectiveMultiplier,0.0,2.0)
				end
			end
		end
		--sb.logInfo("FR_racialStats post: %s",derp)
		status.setPersistentEffects("FR_racialStats", self.helper.speciesConfig.stats or {})

		-- Add any other special effects
		if self.helper.speciesConfig.special then
			for _,thing in pairs(self.helper.speciesConfig.special) do
				status.addPersistentEffect("FR_special",thing,math.huge)
			end
		end
	end

	-- Update stuff
	--self.helper:clearPersistent()
	if self and self.helper then
		--khe's note. never, ever, fucking, ever send this without parameters. the script previously assumed defaults. THIS IS NOT CORRECT BEHAVIOR. modifiers were stacking from multiple contexts.
		self.helper:applyControlModifiers(self.helper.controlModifiers,self.helper.controlParameters)
	end
	self.helper:runScripts("racialscript", self, dt)

	-- Breath handling
	-- which, as it happens, is already handled by the vanilla script. so this applies TWICE.
	if entity.entityType() ~= "npc" then
		local mouthPosition = vec2.add(mcontroller.position(), status.statusProperty("mouthPosition"))
		if status.statPositive("breathProtection") or world.breathable(mouthPosition)
		or status.statPositive("waterbreathProtection") and world.liquidAt(mouthPosition)
		then
			status.modifyResource("breath", status.stat("breathRegenerationRate") * dt)
		else
			status.modifyResource("breath", -status.stat("breathDepletionRate") * dt)
		end
	end
	tagCaching.update()
	masteries.update(dt)
end

function uninit(...)
	masteries.reset()
	if self.isNpc then
		fuPersistentEffectRecorder.uninit()
	end
	if FR_old_uninit then
		FR_old_uninit(...)
	end
end

--function getLevelByExp(exp)
--    return math.floor((math.sqrt(3) * math.sqrt(243*(exp+1)^2-48600*(exp+1)+3680000)+27 * (exp+1)-2700)^(1/3)/30^(2/3)-(5*10^(2/3))/(3^(1/3)*(math.sqrt(3)*math.sqrt(243*(exp+1)^2-48600*(exp+1)+3680000)+27*(exp+1)-2700)^(1/3))+2)
--end
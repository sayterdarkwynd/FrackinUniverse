require "/scripts/kheAA/transferUtil.lua"

local deltaTime=0

function init()
	transferUtil.init()
	self.itemChances = config.getParameter("itemChances")
	self.inputSlot = config.getParameter("inputSlot")

	self.initialCraftDelay = config.getParameter("craftDelay")
	self.craftDelay = self.craftDelay or self.initialCraftDelay
	storage.combsProcessed = storage.combsProcessed or { count = 0 }
	--sb.logInfo("centrifuge: %s", storage.combsProcessed)

	combsPerJar = 3 -- ref. recipes

	object.setInteractive(true)
end

function deciding(item)
	itemMap = itemMap or {
	        milk      = { cheese = self.itemChances.normal },
	        corn      = { cattlefeed = self.itemChances.normal },
		-- item chances are between 0 and 1, and for any given comb type, the sum of the chances must not exceed 1
		arcticcomb      = { frozenwaxchunk = self.itemChances.normal },
		aridcomb        = { goldensand     = self.itemChances.common },
		coppercomb      = { copperore      = self.itemChances.rare },
		durasteelcomb   = { durasteelore   = self.itemChances.rarest },
		forestcomb      = { goldenwood     = self.itemChances.common },
		flowercomb      = { petalred       = self.itemChances.common / 3,
		                    petalyellow    = self.itemChances.common / 3,
		                    petalblue      = self.itemChances.common / 3 },
		godlycomb       = { matteritem     = self.itemChances.rare },
		goldcomb        = { goldore        = self.itemChances.rarest },
		ironcomb        = { ironore        = self.itemChances.rare },
		junglecomb      = { goldenleaves   = self.itemChances.common },
		flowercomb      = { coalore        = self.itemChances.common / 4,
		                    ironore        = self.itemChances.common / 4,
		                    copperore      = self.itemChances.common / 4,
		                    tungstenore    = self.itemChances.common / 4,
		                    durasteelore   = self.itemChances.rare},
		mooncomb        = { fu_carbon       = self.itemChances.common },
		morbidcomb      = { ghostlywax     = self.itemChances.common,
		                    bone           = self.itemChances.rare},
		mythicalcomb    = { liquidhealing  = self.itemChances.rare,
		                    corvex         = self.itemChances.rarest },
		nocturnalcomb   = { waxchunk       = self.itemChances.common },
		normalcomb      = { waxchunk       = self.itemChances.common },
		plutoniumcomb   = { plutoniumore   = self.itemChances.rare },
		preciouscomb    = { diamond        = self.itemChances.rarest },
		radioactivecomb = { uraniumore     = self.itemChances.rare },
		redcomb         = { redwaxchunk    = self.itemChances.common },
		silkcomb        = { beesilk        = self.itemChances.uncommon },
		silvercomb      = { silverore      = self.itemChances.rarest },
		solariumcomb    = { solariumore    = self.itemChances.rare },
		suncomb         = { sulphur        = self.itemChances.rare },
		titaniumcomb    = { titaniumore    = self.itemChances.rarest },
		tungstencomb    = { tungstenore    = self.itemChances.rarest },
		volcaniccomb    = { liquidlava     = self.itemChances.uncommon },
		aegisaltcomb    = { aegisaltore    = self.itemChances.rarest },
		feroziumcomb    = { feroziumore    = self.itemChances.rarest },
		violiumcomb     = { violiumore     = self.itemChances.rarest },
		magmacomb       = { corefragmentore = self.itemChances.normal,
		                    scorchedcore   = self.itemChances.rare,
		                    liquidlava     = self.itemChances.common },
		eldercomb       = { liquidelderfluid = self.itemChances.normal,
		                    protorockmaterial   = self.itemChances.rare }                    
	}
	if item == nil then return itemMap end
	return itemMap[item.name] -- may be nil
end

function update(dt)
	if not storage.init then
		init()
	end
	if deltaTime > 1 then
		deltaTime=0
		transferUtil.loadSelfContainer()
	else
		deltaTime=deltaTime+dt
	end
	local input = world.containerItems(entity.id())[self.inputSlot]

	if input then
		local output = deciding(input)
		if output then
			workingCombs(input, output)
			animator.setAnimationState("centrifuge", "working")
			return
		end
	end

	if storage.combsProcessed and storage.combsProcessed.count > 0 then
		-- discard the stash if unclaimed by a jarrer within a reasonable time (twice the craft delay)
		storage.combsProcessed.stale = (storage.combsProcessed.stale or (self.initialCraftDelay * 2)) - 1
		if storage.combsProcessed.stale == 0 then
			drawHoney() -- effectively clear the stash, stopping the jarrer from getting it
			--sb.logInfo ("stash dropped")
		--else sb.logInfo ("stash drop in %s time units", storage.combsProcessed.stale)
		end
	end

	animator.setAnimationState("centrifuge", "idle")
	self.craftDelay = self.initialCraftDelay
end

function workingCombs(input, output)
	self.craftDelay = self.craftDelay - 1

	if self.craftDelay <= 0 then
		self.craftDelay = self.initialCraftDelay
		world.containerConsume(entity.id(), { name = input.name, count = 1, data={}})
		stashHoney(input.name)

		local rnd = math.random()

		for item, chance in pairs(output) do
			if rnd <= chance then
				local throw = world.containerAddItems(entity.id(), { name = item, count = 1, data={}})
				if throw then world.spawnItem(throw, entity.position()) end -- hope that the player or an NPC which collects items is around
				break
			end
			rnd = rnd - chance
		end
	end
end

function stashHoney(comb)
	-- For any nearby jarrer (if this is an industrial centrifuge),
	-- Record that we've processed a comb.
	-- The stashed type is the jar object name for the comb type.
	-- If the stashed type is different, reset the count.
	local jar = honeyCheck and honeyCheck(comb)
	if jar then
		if storage.combsProcessed == nil then storage.combsProcessed = { count = 0 } end
		if storage.combsProcessed.type == jar then
			storage.combsProcessed.count = math.min(storage.combsProcessed.count + 1, combsPerJar) -- limit to one jar's worth  in stash at any given time
			storage.combsProcessed.stale = nil
		else
			storage.combsProcessed = { type = jar, count = 1 }
		end
		--sb.logInfo("STASH: %s %s", storage.combsProcessed.count,storage.combsProcessed.type)
	end
end

-- Called by the honey jarrer
function drawHoney()
	if not storage.combsProcessed or storage.combsProcessed.count == 0 then return nil end
	local ret = storage.combsProcessed
	storage.combsProcessed = { count = 0 }
	--sb.logInfo("STASH: Withdrawing")
	return ret
end

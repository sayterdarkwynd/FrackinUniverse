require "/scripts/kheAA/transferUtil.lua"

function init()
	transferUtil.init()

	self.itemChances = config.getParameter("itemChances")
	self.inputSlot = config.getParameter("inputSlot")

	self.initialCraftDelay = config.getParameter("craftDelay")
	self.craftDelay = self.craftDelay or self.initialCraftDelay
	storage.combsProcessed = storage.combsProcessed or { count = 0 }
	--sb.logInfo("centrifuge: %s", storage.combsProcessed)

	combsPerJar = 3 -- ref. recipes

	storage.init = true

	object.setInteractive(true)
end

function deciding(item)
-- item chances are between 0 and 1, and for any given comb type, the sum of the chances must not exceed 1
	itemMapFarm = itemMapFarm or {
		milk      = { cheese = self.itemChances.common },
		liquidwater         = { liquidwastewater       = self.itemChances.common,
		                       fu_hydrogen             = self.itemChances.normal / 2,
		                       fu_oxygen               = self.itemChances.normal / 2 }
	        }
	        
	itemMapBees = itemMapBees or {
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
		ironcomb        = { ironore        = self.itemChances.rarest },
		junglecomb      = { goldenleaves   = self.itemChances.common },
		minercomb       = { coalore        = self.itemChances.uncommon },
		mooncomb        = { hematite       = self.itemChances.common },
		morbidcomb      = { ghostlywax     = self.itemChances.common },
		mythicalcomb    = { liquidhealing  = self.itemChances.rare },
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
		violiumcomb     = { violiumore     = self.itemChances.rarest }
	        }
	        
        itemMapLiquids = itemMapLiquids or {
		liquidwater         = { liquidwastewater       = self.itemChances.common,
		                       fu_hydrogen             = self.itemChances.normal / 2,
		                       fu_oxygen               = self.itemChances.normal / 2 },
		liquidpoison        = { liquidwastewater       = self.itemChances.common / 2,
		                       fu_carbon               = self.itemChances.normal,
		                       toxicwaste              = self.itemChances.common / 2 },
		liquidlava          = { coalore                = self.itemChances.common / 3,
		                       corefragmentore         = self.itemChances.common / 3,
		                       fu_carbon               = self.itemChances.common / 3 },
		liquidslime         = { liquidwastewater       = self.itemChances.common / 2,
		                       greenslime              = self.itemChances.common / 2,
		                       endomorphicjelly        = self.itemChances.uncommon },
		liquidoil           = { liquidwastewater       = self.itemChances.common / 3,
		                       fu_carbon               = self.itemChances.common / 3,
		                       coalore                 = self.itemChances.common / 3 },
		liquidfuel          = { liquidwastewater       = self.itemChances.common / 2,
		                       toxicwaste              = self.itemChances.common / 2,
		                       ff_silicon              = self.itemChances.normal },
		liquidhealing       = { liquidwastewater       = self.itemChances.common,
		                       ff_silicon              = self.itemChances.uncommon,
		                       fu_oxygen               = self.itemChances.normal  },
		swampwater          = { dnasample              = self.itemChances.uncommon ,
		                       liquidwater             = self.itemChances.common / 5,
		                       algaegreen              = self.itemChances.common / 5,
		                       nutrientpaste           = self.itemChances.common / 5,
		                       geneticmaterial         = self.itemChances.common / 5,
		                       tissueculture           = self.itemChances.common / 5 },
		liquidblood         = { liquidwastewater       = self.itemChances.common,
		                       geneticmaterial         = self.itemChances.normal / 3,
		                       tissueculture           = self.itemChances.normal / 3,
		                       dnasample               = self.itemChances.normal / 3 },
		liquidbioooze       = { liquidwastewater       = self.itemChances.common / 3,
		                       liquidpoison            = self.itemChances.common / 3,
		                       ff_silicon              = self.itemChances.common / 3 },
		liquidblacktar      = { liquidwastewater       = self.itemChances.common / 3,
		                       liquidoil               = self.itemChances.common / 3,
		                       fu_carbon               = self.itemChances.common / 3 },
		liquidorganicsoup   = { liquidwastewater       = self.itemChances.common / 4,
		                       geneticmaterial         = self.itemChances.common / 4,
		                       dnasample               = self.itemChances.common / 4,
		                       tissueculture           = self.itemChances.common / 4 },
		vialproto           = { liquidwastewater       = self.itemChances.common / 3,
		                       rawminerals             = self.itemChances.common / 3,
		                       nutrientpaste           = self.itemChances.common / 3,
		                       protociteore            = self.itemChances.rare },
		liquidelderfluid    = { liquidwastewater       = self.itemChances.common / 2,
		                       plutoniumore            = self.itemChances.common / 2,
		                       rawminerals             = self.itemChances.common / 3,
		                       aliencompound           = self.itemChances.uncommon },
		liquidsulphuricacid = { liquidwastewater       = self.itemChances.common / 3,
		                       sulphur                 = self.itemChances.common / 3,
		                       fu_carbon               = self.itemChances.common / 3 },
		liquidirradium      = { sulphur                = self.itemChances.common / 2,
		                       irradiumore             = self.itemChances.rare,
		                       fu_nitrogen             = self.itemChances.common / 2 },
		ff_mercury          = { liquidwastewater       = self.itemChances.common / 2,
		                       ironore                 = self.itemChances.common / 2,
		                       fu_carbon               = self.itemChances.uncommon  },
		liquidgravrain      = { liquidwastewater       = self.itemChances.common / 3,
		                       sulphur                 = self.itemChances.uncommon / 3,
		                       rawminerals             = self.itemChances.uncommon / 3,
		                       ff_silicon              = self.itemChances.uncommon / 3 },
		liquidironfu        = { liquidoil              = self.itemChances.uncommon,
		                       ironore                 = self.itemChances.common,
		                       fu_carbon               = self.itemChances.rare },
		liquidpus           = { liquidbioooze          = self.itemChances.common / 3,
		                       nutrientpaste           = self.itemChances.common / 3,
		                       tissueculture           = self.itemChances.common / 3,
		                       dnasample               = self.itemChances.rare},
		fu_liquidhoney      = { liquidwastewater       = self.itemChances.common / 3,
		                       geneticmaterial         = self.itemChances.common / 3,
		                       nutrientpaste           = self.itemChances.common / 3 },
		liquidalienjuice    = { liquidwastewater       = self.itemChances.common / 3,
		                       geneticmaterial         = self.itemChances.common / 3,
		                       ff_silicon              = self.itemChances.common / 3 },
		liquidnitrogenitem  = { liquidwastewater       = self.itemChances.common / 3,
		                       fu_nitrogen             = self.itemChances.common / 3,
		                       icecrystal              = self.itemChances.rare },
		liquiddarkwater     = { liquidwastewater       = self.itemChances.common / 3,
		                       nutrientpaste           = self.itemChances.common / 3,
		                       mineralsample           = self.itemChances.common / 3,
		                       liquidpoison            = self.itemChances.common / 3 },
		liquidaether        = { vialproto              = self.itemChances.rare,
		                       aliencompound           = self.itemChances.rarest,
		                       fu_hydrogen             = self.itemChances.common / 2,
		                       fu_carbon               = self.itemChances.common / 2 },
		liquidwastewater        = { liquidwater        = self.itemChances.common  }			 		                           
        }
        
	itemMapIsotopes = itemMapIsotopes or {
		liquidmetallichydrogen  = { fu_hydrogenmetallic    = self.itemChances.rarest,
		                           fu_hydrogen             = self.itemChances.common / 2,
		                           fu_carbon               = self.itemChances.common / 2 },
		liquiddeuterium         = { deuterium              = self.itemChances.rare,
		                           fu_hydrogen             = self.itemChances.common / 2,
		                           fu_carbon               = self.itemChances.common / 2 },
		toxicwaste              = { uraniumore             = self.itemChances.common,
		                           tritium                 = self.itemChances.rarest },	
		uraniumrod              = { enricheduranium        = self.itemChances.rare,
		                           toxicwaste              = self.itemChances.common / 2,
		                           fu_hydrogen             = self.itemChances.common / 2 }, 
		plutoniumrod            = { enrichedplutonium      = self.itemChances.rare,
		                           fu_hydrogen             = self.itemChances.common / 2,
		                           toxicwaste              = self.itemChances.common / 2 }, 
		neptuniumrod            = { toxicwaste             = self.itemChances.common / 2,
		                           fu_hydrogen             = self.itemChances.common / 2,
		                           ultronium               = self.itemChances.rarest },  
		thoriumrod              = { toxicwaste             = self.itemChances.common / 2,
		                           fu_hydrogen             = self.itemChances.common / 2,
		                           ultronium               = self.itemChances.rarest }, 
		solariumstar            = { ultronium              = self.itemChances.rare,
		                           toxicwaste              = self.itemChances.common / 2,
		                           fu_hydrogen             = self.itemChances.common / 2 }, 
		tritium                 = { uraniumrod             = self.itemChances.common / 2,
		                           liquidmetallichydrogen  = self.itemChances.rare,
		                           fu_hydrogenmetallic     = self.itemChances.rarest,
		                           fu_carbon               = self.itemChances.common / 2 }, 
		deuterium               = { tritium                = self.itemChances.uncommon,
		                           liquidmetallichydrogen  = self.itemChances.rare,
		                           fu_carbon               = self.itemChances.common } 
	}

        mapFarm = config.getParameter("centrifugeFarm")
        mapBees = config.getParameter("centrifugeBee")
        mapLiquid = config.getParameter("centrifugeLiquid")
        mapIsotope = config.getParameter("centrifugeIso")
        if mapFarm and not mapBees and not mapLiquid and not mapIsotope then
	  if item == nil then return itemMapFarm end
	  return itemMapFarm[item.name] -- may be nil        
	elseif mapBees and not mapFarm and not mapLiquid and not mapIsotope then
	  if item == nil then return itemMapBees end
	  return itemMapBees[item.name] or itemMapFarm[item.name] -- may be nil
	elseif mapLiquid and not mapFarm and not mapBees and not mapIsotope then
	  if item == nil then return itemMapBees or itemMapLiquids end
	  return itemMapBees[item.name] or itemMapLiquids[item.name] -- may be nil
	elseif mapIsotope and not mapFarm and not mapBees and not mapLiquid then
	  if item == nil then return itemMapBees or itemMapLiquids or itemMapIso end
	  return itemMapBees[item.name] or itemMapLiquids[item.name] or itemMapIsotopes[item.name] -- may be nil
	end
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

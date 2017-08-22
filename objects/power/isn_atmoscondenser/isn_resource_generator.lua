require "/scripts/util.lua"
require "/scripts/kheAA/transferUtil.lua"
require "/scripts/power.lua"

local deltaTime=0

local biomes = {
  aethersea = {
    rare = {output = "aetherrareOutputs",cooldown = 10},
	uncommon = {output = "aetheruncommonOutputs",cooldown = 6},
	normal = {output = "aetherOutputs",cooldown = 3}
  },
  moon = {
    rare = {output = "moonrareOutputs",cooldown = 8},
	uncommon = {output = "moonuncommonOutputs",cooldown = 4.5},
	normal = {output ="moonOutputs",cooldown = 3}
  },
  moon_desert = {
    rare = {output = "moonrareOutputs",cooldown = 8},
	uncommon = {output = "moonuncommonOutputs",cooldown = 4.5},
	normal = {output ="moonOutputs",cooldown = 3}
  },
  moon_shadow = {
    rare = {output = "moonrareOutputs",cooldown = 8},
	uncommon = {output = "moonuncommonOutputs",cooldown = 4.5},
	normal = {output = "moonOutputs",cooldown = 3}
  },
  moon_stone = {
    rare = {output = "moonrareOutputs",cooldown = 8},
	uncommon = {output = "moonuncommonOutputs",cooldown = 4.5},
	normal = {output = "moonOutputs",cooldown = 3}
  },
  moon_volcanic = {
    rare = {output = "moonrareOutputs",cooldown = 8},
	uncommon = {output = "moonuncommonOutputs",cooldown = 4.5},
	normal = {output = "moonOutputs",cooldown = 3}
  },
  moon_toxic = {
    rare = {output = "moonrareOutputs",cooldown = 8},
	uncommon = {output = "moonuncommonOutputs",cooldown = 4.5},
	normal = {output = "moonOutputs",cooldown = 3}
  },
  atropus = {
    rare = {output = "atropusrareOutputs",cooldown = 7},
	uncommon = {output = "atropusuncommonOutputs",cooldown = 3.5},
	normal = {output = "atropusOutputs",cooldown = 2}
  },
  atropusdark = {
    rare = {output = "atropusrareOutputs",cooldown = 8},
	uncommon = {output = "atropusuncommonOutputs",cooldown = 3.5},
	normal = {output = "atropusOutputs",cooldown = 2}
  },
  fugasgiant = {
    rare = {output = "gasrareOutputs",cooldown = 10},
	uncommon = {output = "gasuncommonOutputs",cooldown = 4.5},
	normal = {output = "gasOutputs",cooldown = 2}
  },
  fugasgiant2 = {
    rare = {output = "gasrareOutputs",cooldown = 10},
	uncommon = {output = "gasuncommonOutputs",cooldown = 4.5},
	normal = {output = "gasOutputs",cooldown = 2}
  },
  fugasgiant3 = {
    rare = {output = "gasrareOutputs",cooldown = 10},
	uncommon = {output = "gasuncommonOutputs",cooldown = 4.5},
	normal = {output = "gasOutputs",cooldown = 2}
  },
  fugasgiant4 = {
    rare = {output = "gasrareOutputs",cooldown = 10},
	uncommon = {output = "gasuncommonOutputs",cooldown = 4.5},
	normal = {output = "gasOutputs",cooldown = 2}
  },
  fugasgiant5 = {
    rare = {output = "gasrareOutputs",cooldown = 10},
	uncommon = {output = "gasuncommonOutputs",cooldown = 4.5},
	normal = {output = "gasOutputs",cooldown = 2}
  },
  bog = {
    rare = {output = "bograreOutputs",cooldown = 5},
	uncommon = {output = "boguncommonOutputs",cooldown = 3.5},
	normal = {output = "bogOutputs",cooldown = 2}
  },
  chromatic = {
    rare = {output = "chromaticrareOutputs",cooldown = 6},
	uncommon = {output = "chromaticuncommonOutputs",cooldown = 4.5},
	normal = {output = "chromaticOutputs",cooldown = 2}
  },
  crystalmoon = {
    rare = {output = "crystalrareOutputs",cooldown = 7},
	uncommon = {output = "crystaluncommonOutputs",cooldown = 5.5},
	normal = {output = "crystalOutputs",cooldown = 4}
  },
  desert = {
    rare = {output = "desertrareOutputs",cooldown = 5},
	uncommon = {output = "desertuncommonOutputs",cooldown = 3.5},
	normal = {output = "desertOutputs",cooldown = 2}
  },
  desertwastes = {
    rare = {output = "desertrareOutputs",cooldown = 5},
	uncommon = {output = "desertuncommonOutputs",cooldown = 3.5},
	normal = {output = "desertOutputs",cooldown = 2}
  },
  desertwastesdark = {
    rare = {output = "desertrareOutputs",cooldown = 5},
	uncommon = {output = "desertuncommonOutputs",cooldown = 3.5},
	normal = {output = "desertOutputs",cooldown = 2}
  },
  icewaste = {
    rare = {output = "icerareOutputs",cooldown = 8},
	uncommon = {output = "iceuncommonOutputs",cooldown = 3.5},
	normal = {output = "iceOutputs",cooldown = 2}
  },
  icewastedark = {
    rare = {output = "icerareOutputs",cooldown = 8},
	uncommon = {output = "iceuncommonOutputs",cooldown = 3.5},
	normal = {output = "iceOutputs",cooldown = 2}
  },
  nitrogensea = {
    rare = {output = "nitrogenrareOutputs",cooldown = 8},
	uncommon = {output = "nitrogenuncommonOutputs",cooldown = 4.5},
	normal = {output = "nitrogenOutputs",cooldown = 2}
  },
  infernus = {
    rare = {output = "infernusrareOutputs",cooldown = 8},
	uncommon = {output = "infernusuncommonOutputs",cooldown = 4.5},
	normal = {output = "infernusOutputs",cooldown = 2}
  },
  infernusdark = {
    rare = {output = "infernusrareOutputs",cooldown = 8},
	uncommon = {output = "infernusuncommonOutputs",cooldown = 4.5},
	normal = {output = "infernusOutputs",cooldown = 2}
  },
  slimeworld = {
    rare = {output = "slimerareOutputs",cooldown = 6},
	uncommon = {output = "slimeuncommonOutputs",cooldown = 4.5},
	normal = {output = "slimeOutputs",cooldown = 2}
  },
  strangesea = {
    rare = {output = "strangesearareOutputs",cooldown = 6},
	uncommon = {output = "strangeseauncommonOutputs",cooldown = 4.5},
	normal = {output = "strangeseaOutputs",cooldown = 2}
  },
  ocean = {
    rare = {output = "oceanrareOutputs",cooldown = 5},
	uncommon = {output = "oceanuncommonOutputs",cooldown = 3.5},
	normal = {output = "oceanOutputs",cooldown = 2}
  },
  sulphuric = {
    rare = {output = "sulphuricrareOutputs",cooldown = 6},
	uncommon = {output = "sulphuricuncommonOutputs",cooldown = 3.5},
	normal = {output = "sulphuricOutputs",cooldown = 2}
  },
  sulphuricdark = {
    rare = {output = "sulphuricrareOutputs",cooldown = 6},
	uncommon = {output = "sulphuricuncommonOutputs",cooldown = 3.5},
	normal = {output = "sulphuricOutputs",cooldown = 2}
  },
  sulphuricocean = {
    rare = {output = "sulphuricrareOutputs",cooldown = 6},
	uncommon = {output = "sulphuricuncommonOutputs",cooldown = 3.5},
	normal = {output = "sulphuricOutputs",cooldown = 2}
  },
  tarball = {
    rare = {output = "tarballrareOutputs",cooldown = 6},
	uncommon = {output = "tarballuncommonOutputs",cooldown = 4.5},
	normal = {output = "tarballOutputs",cooldown = 2}
  },
  toxic = {
    rare = {output = "toxicrareOutputs",cooldown = 7},
	uncommon = {output = "toxicuncommonOutputs",cooldown = 3.5},
	normal = {output = "toxicOutputs",cooldown = 2}
  },
  metallicmoon = {
    rare = {output = "metallicrareOutputs",cooldown = 7},
	uncommon = {output = "metallicuncommonOutputs",cooldown = 3.5},
	normal = {output = "metallicOutputs",cooldown = 2}
  },
  lightless = {
    rare = {output = "lightlessrareOutputs",cooldown = 7},
	uncommon = {output = "lightlessuncommonOutputs",cooldown = 3.5},
	normal = {output = "lightlessOutputs",cooldown = 2}
  },
  penumbra = {
    rare = {output = "penumbrarareOutputs",cooldown = 6},
	uncommon = {output = "penumbrauncommonOutputs",cooldown = 4.5},
	normal = {output = "penumbraOutputs",cooldown = 2}
  },
  protoworld = {
    rare = {output = "protorareOutputs",cooldown = 6},
	uncommon = {output = "protouncommonOutputs",cooldown = 4.5},
	normal = {output = "protoOutputs",cooldown = 2}
  },
  protoworlddark = {
    rare = {output = "protorareOutputs",cooldown = 6},
	uncommon = {output = "protouncommonOutputs",cooldown = 4.5},
	normal = {output = "protoOutputs",cooldown = 2}
  },
  irradiated = {
    rare = {output = "radiationrareOutputs",cooldown = 7},
	uncommon = {output = "radiationuncommonOutputs",cooldown = 4.5},
	normal = {output = "radiationOutputs",cooldown = 2}
  },
  fungus = {
    rare = {output = "fungusrareOutputs",cooldown = 5.3},
	uncommon = {output = "fungusuncommonOutputs",cooldown = 3.7},
	normal = {output = "fungusOutputs",cooldown = 2}
  },
  other = {
    rare = {output = "rareOutputs",cooldown = 5},
	uncommon = {output = "uncommonOutputs",cooldown = 3.5},
	normal = {output = "commonOutputs",cooldown = 2}
  }
}

function init()
  transferUtil.init()
  object.setInteractive(true)
  self.timer = 1
  power.init()
end

function update(dt)
  self.timer = self.timer - dt

  if deltaTime > 1 then
	deltaTime=0
	transferUtil.loadSelfContainer()
  else
	deltaTime=deltaTime+dt
  end

  if self.timer <= 0 then
    local output = nil
    local rarityroll = math.random(1,100)
	local biome = biomes[world.type()] or biomes.other
	if rarityroll == 100 then  
	  biome = biome.rare
	elseif rarityroll >= 79 then
	  biome = biome.uncommon
	else
	  biome = biome.normal
	end
	output = util.randomFromList(config.getParameter(biome.output))
	self.timer = biome.cooldown
    if output and clearSlotCheck(output) and power.consume(config.getParameter('isn_requiredPower')) then
	  animator.setAnimationState("machineState", "active")
      world.containerAddItems(entity.id(), {name = output, count = 1, data={}})
	else
	  animator.setAnimationState("machineState", "idle")
	end
  end
  power.update(dt)
end




function clearSlotCheck(checkname)
  if world.containerItemsCanFit(entity.id(), {name= checkname, count=1, data={}}) > 0 then
	return true
  else
	return false
  end
end
-- Egg Incubation
-- player places egg in incubator
-- egg hatch time is eggs base hatch time +- any modifiers
-- factors that influence egg hatch time are "hardiness", the type of egg, warmth. colder worlds hatch slower (unless a cold-type egg)
-- plus every egg also gets a random variable attached to it that can change the hatch time, so each egg is a bit unique

function init()
  -- egg type?
  self.centrifugeType = config.getParameter("centrifugeType")
  incubation = {  -- monster to spawn, incubation time, success rate (0-1)
    default = {"fuhenbaby", 400, 1},
    egg = {"fuhenbaby", 400, 0.5},
    henegg = {"fuhenbaby", 400, 1},
    primedegg = {"fuhenbaby", 200, 1},
    poptopegg = {"fupoptopfarm", 600, 1},
    raptoregg = {"furaptor4", 1200, 1},
    raptoregg2 = {"furaptor5", 1200, 1},
    raptoregg3 = {"furaptor9", 1200, 1},
    raptoregg4 = {"furaptor10", 1200, 1},
    raptoregg5 = {"furaptor11", 1200, 1},
    pangolinegg = {"pangobaby", 600, 1},
    firefluffaloegg = {"fufirefluffalo", 800, 1},
    poisonfluffaloegg =  {"fupoisonfluffalo", 800, 1},
    icefluffaloegg = {"fuicefluffalo", 800, 1},
    electricfluffaloegg = {"fuelectricfluffalo", 800, 1},
    fluffaloegg = {"fufluffalo", 400, 1},
    robothenegg = {"furobothenbaby", 400, 1},
    mooshiegg = {"fumooshibaby", 300, 1},
    copperbeakegg = {"fudodofarmbaby", 320, 1},
    ironbeakegg = {"fudodofarmironbaby", 520, 1},
    fuorbisegg = {"fuorbis", 620, 1},
    erchibudegg = {"erchibudbaby", 500, 1},
    slimeshoategg = {"slimeshoatbaby", 400, 1},
    gooshoategg = {"gooshoatbaby", 400, 1},
    greenshoategg = {"greenshoatbaby", 400, 1},
    normaldrone = {"normalbee", 10, 1},
    larva = {"maggot", 20, 1}
  }
  -- egg modifiers
  eggmodifiers = {
    default = 1
  }

  spawnMod = math.random(10) -- + config.getParameter("spawnModValue") -- change this to check the egg instead. each egg has a spawnMod that influences its hatch time
  storage.warmth = 0 -- is world temperature suitable? warmer weather reduces spawn time unless it likes cold
  storage.hardiness = 0 -- how tough is the egg? the tougher it is, the longer it takes to hatch
end


function fillPercent(container)
  if type(container) ~= "number" then return nil end
  local size = world.containerSize(container)
  local count = 0
  for i = 0,size,1 do
    local item = world.containerItemAt(container, i)

    if item ~= nil then
      count = count + 1

      if size == 1 then
        size = 1000
        count = item.count
      end
    end
  end
  return (count/size)
end

function binInventoryChange()
  if entity.id() then
    local container = entity.id()
    local frames = config.getParameter("binFrames", 10) - 1
    local fill = math.ceil(frames * fillPercent(container))
    if self.fill ~= fill then
      self.fill = fill
      animator.setAnimationState("fillState", tostring(fill))
    end
  end
end

function update()
  fillPercent()
  binInventoryChange()
  checkHatching()
end

function checkHatching()
  if entity.id() then
    local container = entity.id()
    local item = world.containerItemAt(container, 0)

    if item ~= nil and incubation[item.name] ~= nil then

      -- set incubation time
      if storage.incubationTime == nil then
        storage.incubationTime = os.time()
      end

      -- set the eggs current age
      local age = (os.time() - storage.incubationTime) - spawnMod

      -- base hatch time
      local hatchTime = incubation[item.name][2]
      if hatchTime == nil then   -- Cannot ever be true, since this if-block never gets run if hatchTime would be nil
        hatchTime = incubation.default
      end

      -- forced hatch time
      local forceHatchTime = item.forceHatchTime
      if forceHatchTime == nil then
        forceHatchTime = (hatchTime / 2)
      end

      -- set visual growth bar on the incubator
      self.indicator = math.ceil( (age / hatchTime) * 9)

      -- hatching check
      if age >= hatchTime then
        hatchEgg()
        self.indicator = 0
        storage.incubationTime = nil
        self.timer = 0
      end

      if self.indicator == nil then self.indicator = 0 end

      if self.timer == nil or self.timer > self.indicator then
        self.timer = self.indicator
      end

      if self.timer > -1 then
        animator.setGlobalTag("bin_indicator", self.timer)
      end
      self.timer = self.timer + 1
    end
  end
end

function hatchEgg()  --make the baby
  local container = entity.id()
  local item = world.containerTakeNumItemsAt(container, 0, 1)

  if item then
    if (math.random() < incubation[item.name][3]) then
      local spawnposition = entity.position()
      spawnposition[2] = spawnposition[2] + 2
      local parameters = {}
      parameters.persistent = true
      parameters.damageTeam = 0
      parameters.startTime = os.time()
      parameters.damageTeamType = "passive"

      if item.name == "goldenegg" then
        world.spawnItem("money", spawnposition, 5000)
      elseif self.centrifugeType == "cloning" then -- are we cloning bees/eggs?
        world.spawnMonster(incubation[item.name][1], spawnposition, parameters)
        world.spawnMonster(incubation[item.name][1], spawnposition, parameters)
        self.indicator = 0
        storage.incubationTime = nil
        self.timer = 0
        animator.setGlobalTag("bin_indicator", self.timer)
      else
        self.indicator = 0
        storage.incubationTime = nil
        self.timer = 0
        animator.setGlobalTag("bin_indicator", self.timer)
        world.spawnMonster(incubation[item.name][1], spawnposition, parameters)
      end
    else
      world.containerPutItemsAt(container, {name = "rottenfood", amount = 1}, 0)
    end
  end
  storage.incubationTime = nil
end

-- Egg Incubation
-- player places egg in incubator
-- egg hatch time is eggs base hatch time +- any modifiers
-- factors that influence egg hatch time are "hardiness", the type of egg, warmth. colder worlds hatch slower (unless a cold-type egg)
-- plus every egg also gets a random variable attached to it that can change the hatch time, so each egg is a bit unique

function init()
  -- egg type?
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
    firefluffaloegg = {"fufirefluffalo", 800, 1},
    poisonfluffaloegg =  {"fupoisonfluffalo", 800, 1},
    icefluffaloegg = {"fuicefluffalo", 800, 1},
    electricfluffaloegg = {"fuelectricfluffalo", 800, 1},
    fluffaloegg = {"fufluffalo", 400, 1},
    robothenegg = {"furobothenbaby", 400, 1},
    mooshiegg = {"fumooshibaby", 300, 1},
    copperbeakegg = {"fudodofarmbaby", 120, 1}
  }
  -- egg modifiers
  eggmodifiers = {
    default = 1
  }


  -- change this to check the egg instead. each egg has a spawnMod that influences its hatch time
  spawnMod = math.random(10) -- + config.getParameter("spawnModValue")

  -- is world temperature suitable? warmer weather reduces spawn time unless it likes cold
  storage.warmth = 0
  storage.cold = 0

  -- how tough is the egg? the tougher it is, the longer it takes to hatch
  storage.hardiness = 0
end


function update()
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
      --sb.logInfo("Incubation time: %s", storage.incubationTime)

      -- set the eggs current age
      local age = (os.time() - storage.incubationTime) - spawnMod
      --sb.logInfo("age: %s", age)
      --sb.logInfo("hatch modifier: %s", spawnMod)

      -- base hatch time
      local hatchTime = incubation[item.name][2]
      if hatchTime == nil then   -- Cannot ever be true, since this if-block never gets run if hatchTime would be nil
        hatchTime = incubation.default
        --sb.logInfo("Hatch time: %s", hatchTime)
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
        age = 0
        self.indicator = 0
        storage.incubationTime = nil
        self.timer = 0
      end

      if self.indicator == nil then self.indicator = 0 end
      if self.timer == nil or self.timer > self.indicator then self.timer = self.indicator - 1 end
      if self.timer > -1 then animator.setGlobalTag("bin_indicator", self.timer) end
      self.timer = self.timer + 1
    else
      storage.incubationTime = nil
      self.indicator = 0
      self.timer = 0
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
      else
        world.spawnMonster(incubation[item.name][1], spawnposition, parameters)
      end
    else
      world.containerPutItemsAt(container, {name = "rottenfood", amount = 1}, 0)
    end
  end
  storage.incubationTime = nil
end

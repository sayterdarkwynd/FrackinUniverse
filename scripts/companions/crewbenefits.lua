-- This version adds some crew benefit limitations

require "/scripts/util.lua"

local benefitTypes = {}

Benefit = {}
Benefit.__index = Benefit

function Benefit:new(definition, store)
  local benefit = setmetatable({}, self)
  benefit.definition = definition
  benefit:init(store)
  return benefit
end

function Benefit:init()
end

function Benefit:store()
end

function Benefit:shipUpdate(recruit, dt)
end

function Benefit:persistentEffects()
  return {}
end

function Benefit:ephemeralEffects()
  return {}
end

function Benefit:regenerationAmount()
  return 0
end

benefitTypes.EphemeralEffect = setmetatable({}, Benefit)
benefitTypes.EphemeralEffect.__index = benefitTypes.EphemeralEffect

function benefitTypes.EphemeralEffect:ephemeralEffects()
  if self.definition.duration then
    return {{
        effect = self.definition.effect,
        duration = self.definition.duration
      }}
  else
    return { self.definition.effect }
  end
end

benefitTypes.PersistentEffect = setmetatable({}, Benefit)
benefitTypes.PersistentEffect.__index = benefitTypes.PersistentEffect

function benefitTypes.PersistentEffect:persistentEffects()
  return { self.definition.effect }
end

benefitTypes.Regeneration = setmetatable({}, Benefit)
benefitTypes.Regeneration.__index = benefitTypes.Regeneration

function benefitTypes.Regeneration:regenerationAmount()
  return self.definition.value
end

local PeriodicBenefit = setmetatable({}, Benefit)
PeriodicBenefit.__index = PeriodicBenefit
PeriodicBenefit.operation = nil

function PeriodicBenefit:init(store)
  self.startTime = (store and store.startTime) or world.time()
end

function PeriodicBenefit:store()
  return {
      startTime = self.startTime
    }
end

-- MODIFIED FUNCTION
function PeriodicBenefit:applyOperation()
  local shipUpgrades = player.shipUpgrades()
  assert(shipUpgrades[self.definition.property] and self.operation)

  local initialValue = shipUpgrades[self.definition.property]
  local limit = self.definition.limit
  if limit and initialValue >= limit then
    return false -- already above limit; signal nothing to do
  end

  local newValue = self.operation(initialValue, self.definition.value)
  if limit and newValue > limit then
    newValue = limit -- clamp to max
  end
  if initialValue == newValue then
    return false -- no change: signal nothing to do
  end

  shipUpgrades[self.definition.property] = newValue
  player.upgradeShip(shipUpgrades)
  return true
end

-- MODIFIED FUNCTION
function PeriodicBenefit:shipUpdate(recruit, dt)
  local now = world.time()
  local elapsed = now - self.startTime
  if elapsed >= self.definition.period then
    self.startTime = now

    if not self:applyOperation() then
      return -- nothing to do
    end

    recruit:sendMessage("notify", {
        type = "shipImprovementApplied",
        sourceId = entity.id()
      })
  end
end

benefitTypes.PeriodicMultiplier = setmetatable({}, PeriodicBenefit)
benefitTypes.PeriodicMultiplier.__index = benefitTypes.PeriodicMultiplier
benefitTypes.PeriodicMultiplier.operation = function (a,b) return a*b end

benefitTypes.PeriodicIncrease = setmetatable({}, PeriodicBenefit)
benefitTypes.PeriodicIncrease.__index = benefitTypes.PeriodicIncrease
benefitTypes.PeriodicIncrease.operation = function (a,b) return a+b end

local Composite = setmetatable({}, Benefit)
Composite.__index = Composite

function Composite:init(store)
  store = store or {}
  self.benefits = util.mapWithKeys(self.definition or {}, function (key, definition)
      return loadBenefits(definition, store[key])
    end)
end

function Composite:store()
  return util.mapWithKeys(self.definition or {}, function (key, _)
      return self.benefits[key]:store()
    end)
end

function Composite:persistentEffects()
  local effects = {}
  for _,benefit in pairs(self.benefits) do
    util.appendLists(effects, benefit:persistentEffects())
  end
  return effects
end

function Composite:ephemeralEffects()
  local effects = {}
  for _,benefit in pairs(self.benefits) do
    util.appendLists(effects, benefit:ephemeralEffects())
  end
  return effects
end

function Composite:regenerationAmount()
  local amount = 0
  for _, benefit in pairs(self.benefits) do
    amount = amount + benefit:regenerationAmount()
  end
  return amount
end

function Composite:shipUpdate(recruit, dt)
  for _, benefit in pairs(self.benefits) do
    benefit:shipUpdate(recruit, dt)
  end
end

function loadBenefits(definition, store)
  if not definition or isEmpty(definition) or definition[1] then
    return Composite:new(definition, store)
  else
    local benefitClass = benefitTypes[definition.type]
    return benefitClass:new(definition, store)
  end
end

function getRegenerationEffect(type, regeneration)
  if regeneration == 0 then return nil end
  local regenEffects = config.getParameter("crewBenefits."..type.."Regeneration")
  local effectName = regenEffects[regeneration] or regenEffects[#regenEffects]
  return effectName
end

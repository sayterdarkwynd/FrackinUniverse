require "/scripts/kheAA/transferUtil.lua"
require "/scripts/kheAA/liquidLib.lua"
local deltaTime = 0

function init()
  transferUtil.init()
  object.setInteractive(true)

  self.defaultOnAnimation = config.getParameter("defaultOnAnimation","other")
  self.defaultOffAnimation = config.getParameter("defaultOffAnimation","off")
end

-- Compares the stored object's 'liquid' field against the sampled liquid's name.
function isOn()
  local predicateId = predicateLiquidId()
  local sampleId = sampleLiquidId()
  local on = sampleId and predicateId == sampleId
  return on
end

function sampleLiquidId()
  local sample = world.liquidAt(object.position())
  if (sample == nil) then
    return nil 
  end
  return sample[1]
end

function predicateLiquidId()
  local predicate = world.containerItemAt(entity.id(), 0)
  if (predicate == nil) then 
    return nil 
  end
  return liquidLib.itemToLiquidId(predicate)
end

function update(dt)
  deltaTime = deltaTime + dt
  if deltaTime > 1 then
    deltaTime = 0
    transferUtil.loadSelfContainer()
  end

  local on = isOn()

  if on then 
    object.setOutputNodeLevel(0, true)
    animator.setAnimationState("sensorState", self.defaultOnAnimation)
  else 
    object.setOutputNodeLevel(0, false)
    animator.setAnimationState("sensorState", self.defaultOffAnimation)
  end
end
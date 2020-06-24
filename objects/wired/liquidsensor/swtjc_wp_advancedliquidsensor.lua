require "/scripts/kheAA/transferUtil.lua"
require "/scripts/kheAA/liquidLib.lua"
local deltaTime = 0

function init()
  transferUtil.init()
  object.setInteractive(true)

  self.defaultOnAnimation = config.getParameter("defaultOnAnimation","other")
  self.defaultOffAnimation = config.getParameter("defaultOffAnimation","off")
end

function sampleLiquid()
  return world.liquidAt(object.position())
end

-- Compares the stored object's 'liquid' field against the sampled liquid's name.
function isOn()
  local predicateId = predicateLiquidId()
  local sampleId = sampleLiquidId()
  local result = sampleId and predicateId == sampleId
  return result
end

function sampleLiquidId()
  local sample = sampleLiquid()
  if (sample == nil) then
    sb.logInfo("sample nil")
    return nil 
  end
  return sample[1]
end

function predicateLiquidId()
  local id = entity.id()
  local predicate = world.containerItemAt(id, 0)
  if (predicate == nil) then 
    sb.logInfo("predicate nil")
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
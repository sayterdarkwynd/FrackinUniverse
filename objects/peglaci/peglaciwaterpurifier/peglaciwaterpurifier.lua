function init()
  self.watersourcePos = object.position()
  if storage.state == nil then
    output(false)
  else
    output(storage.state)
  end

  self.timer = 0
  self.toStop = 2

  message.setHandler("receiveLiquid", function(_, _, liquidLevel)
    self.timer = self.toStop
    filter(liquidLevel[1],liquidLevel[2])
  end)

end

-- Change Animation
function output(state)
  if state ~= storage.state then
    storage.state = state
    if state then
      animator.setAnimationState("purifierState", "on")
    else
      animator.setAnimationState("purifierState", "off")
    end
  end
end

function filter(id, amount)
  conversionTable = root.assetJson("/objects/peglaci/peglaciwaterpurifier/liquidconversion.config")

  convertData = conversionTable[sb.print(id)]

  if convertData ~= nil then
    world.spawnLiquid(self.watersourcePos,convertData[2],convertData[1] * amount)
  else
    world.spawnLiquid(self.watersourcePos,id,amount)
  end
end

-- creates Liquids at current position
function watersourcelimit(id,amount)
  local waterlevel = world.liquidAt(self.watersourcePos)
  if not waterlevel or waterlevel[2] < 0.7 then
    world.spawnLiquid(self.watersourcePos,id,amount)
  end
end

function update(dt)

  if self.timer > 0  then
    self.timer = self.timer - dt
    output(true)
  else
    output(false)
  end
end

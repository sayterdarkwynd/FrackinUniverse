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
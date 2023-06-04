function main()
  if entity.id() then
    local dayTime = -world.timeOfDay() * 2 * math.pi * entity.direction()
    entity.rotateGroup("time", dayTime)
  end
end
function init(args)
  if not virtual then
    storage.pos = {entity.position(), {entity.position()[1] + 1, entity.position()[2]}, {entity.position()[1] - 1, entity.position()[2]}}
  end
end

function main()
  if world.liquidAt(storage.pos[1])then
    world.destroyLiquid(storage.pos[1])
  end
end
function spawn(pattern)
  local initialPosition = vec2.add(self.position, {-pattern.offset[1], -pattern.offset[2]})
  local spawnPosition = vec2.add(initialPosition, {pattern.boundingBox[1]/2, pattern.boundingBox[2]/2})
  spawnResult(pattern, spawnPosition)
end

function evolve(evolution)
  local eType = entity.entityType()
  if eType == "monster" then
    monster.setDropPool()
  elseif eType == "npc" then
    npc.setDropPool()
  end
  status.setResource("health", 0)
  spawnResult(evolution, self.position)
end

function spawnResult(result, position)
  if result.npcSpawn then
    world.spawnNpc(position, result.npcSpawn.species, result.npcSpawn.npcType, world.threatLevel(), nil, result.npcSpawn.parameters or {})
  end
  if result.monsterSpawn then
    world.spawnMonster(result.monsterSpawn.type, vec2.add(position, {0, 3}), result.monsterSpawn.parameters or {})
  end
  if result.itemSpawn then
    world.spawnItem(result.itemSpawn.name, position, result.itemSpawn.count or 1, result.itemSpawn.parameters or {})
  end
end

function spawn(pattern)
  local initialPosition = vec2.add(self.position, {-pattern.offset[1], -pattern.offset[2]})
  local spawnPosition = vec2.add(initialPosition, {pattern.boundingBox[1]/2, pattern.boundingBox[2]/2})
  if pattern.npcSpawn then
    world.spawnNpc(spawnPosition, pattern.npcSpawn.species, pattern.npcSpawn.npcType, world.threatLevel())
  end
  if pattern.monsterSpawn then
    world.spawnMonster(pattern.monsterSpawn.type, spawnPosition)
  end
end

function evolve(evolution)
  status.setResource("health", 0)
  if evolution.npcSpawn then
    world.spawnNpc(self.position, evolution.npcSpawn.species, evolution.npcSpawn.npcType, world.threatLevel())
  end
  if evolution.monsterSpawn then
    world.spawnMonster(evolution.monsterSpawn.type, vec2.add(self.position, {0, 3}))
  end
end

require "/scripts/status.lua"
require "/scripts/util.lua"
require "/scripts/interp.lua"

pandorasboxPenguinoidStats = {
  pandorasboxpenguin = {
  stats = {"pandorasboxpenguinjumpsound","pandorasboxpenguincrouchsound"},
  mouthPos = {0.0, -0.40}
  },
  pandorasboxsheye = {
  stats = {"pandorasboxpenguinjumpsound"},
  mouthPos = {0.0, -0.40}
  },
}

penguinoidOldUpdate = update

function update(dt)
  penguinoidOldUpdate(dt)
  if not self.playerSpecie then
    self.playerSpecie = world.entitySpecies(entity.id())
    if self.playerSpecie then
      local penguinoidStat = pandorasboxPenguinoidStats[self.playerSpecie]
      if penguinoidStat then
        status.setStatusProperty("mouthPosition", penguinoidStat.mouthPos)
        status.addPersistentEffects("penguinoidPersistantEffects", penguinoidStat.stats)
      end
    end
  end
end

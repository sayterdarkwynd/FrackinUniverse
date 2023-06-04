require "/scripts/effectUtil.lua"

function init()
  animator.setParticleEmitterOffsetRegion("drips", mcontroller.boundBox())
  animator.setParticleEmitterActive("drips", true)
  script.setUpdateDelta(10)
end

function update(dt)
	effectUtil.effectAllEnemiesInRange("icySlow",6,1)
end

function uninit()
end
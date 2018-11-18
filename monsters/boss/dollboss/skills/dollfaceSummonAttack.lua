--------------------------------------------------------------------------------
dollfaceSummonAttack = {}

function dollfaceSummonAttack.enter()
  if self.targetPosition == nil then return nil end

  return {
    projectileType = config.getParameter("dollfaceSummonAttack.projectileType"),
    maxDolls = config.getParameter("dollfaceSummonAttack.maxDolls"),
    dollCounts = config.getParameter("dollfaceSummonAttack.dollCounts"),
    spawnRange = config.getParameter("dollfaceSummonAttack.spawnRange"),
    interval = config.getParameter("dollfaceSummonAttack.interval"),
    timer = 0.0,
    timer2 = 0.0,
    skillTime = -1.0
  }
end

function dollfaceSummonAttack.enteringState(stateData)
  monster.setActiveSkillName("dollfaceSummonAttack")
end

function dollfaceSummonAttack.update(dt, stateData)
  if stateData.skillTime == -1 then
      dollfaceSummonAttack.getSkillTime(stateData) --skilltime is dynamic
      if stateData.skillTime == 0 then return true end
  end

  stateData.timer = stateData.timer + dt
  stateData.timer2 = stateData.timer2 + dt

  if stateData.timer2 >= stateData.interval then
    stateData.timer2 = 0.0
    --spawning mojo
    local spawnOffset = {}
    while true do
      local magnitude = math.random() * (stateData.spawnRange[2] - stateData.spawnRange[1]) + stateData.spawnRange[1]
      local randAngle = math.random() * math.pi * 2
      local offset = vec2.rotate({magnitude,0}, randAngle)
      spawnOffset = vec2.add(mcontroller.position(),offset)
      if not world.lineTileCollision(mcontroller.position(), spawnOffset) then break end
    end

    animator.playSound("summon")
    world.spawnProjectile(stateData.projectileType, spawnOffset)
  end

  if stateData.timer >= stateData.skillTime then return true
  else return false end
end

function dollfaceSummonAttack.leavingState(stateData)
end

function dollfaceSummonAttack.getSkillTime(stateData)
  local dollcount = stateData.dollCounts[currentPhase()]
  local dollcount2 = 0
  local dolls = world.entityQuery(mcontroller.position(), 60, { includedTypes = {"monster"} })
  for _,doll in pairs(dolls) do
    if world.monsterType(doll) == "doll2" then
      dollcount2 = dollcount2 + 1
    end
  end
  if dollcount + dollcount2 > stateData.maxDolls then
    dollcount = 10-dollcount2
    if dollcount <= 0 then stateData.skillTime = 0 return nil end
  end
  stateData.skillTime = dollcount * stateData.interval
end

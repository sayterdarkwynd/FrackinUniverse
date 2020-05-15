require "/scripts/util.lua"
require "/stats/effects/fu_armoreffects/new/SetBonusHelper.lua"

--============================= CLASS DEFINITION ============================--
--[[ This instantiates a child class of SetBonusHelper. The child's metatable
    is set to the parent's, so that any missing indexes (methods) are looked
    up from SetBonusHelper. The methods can also be accessed manually (in cases
    that extend the parent method) through the child.parent attribute. ]]--

SlimeSetBonus = SetBonusHelper:new({})

function SlimeSetBonus.getThreatLevel(self)
  if world.getProperty("ship.fuel") ~= nil then return 1 end
  if world.threatLevel() then return world.threatLevel() end
  return 1
end

function SlimeSetBonus.resetSpawnTimer(self)
  self.spawnTimer = self.spawnDelayBase + math.random(self.spawnDelayRange)
end

function SlimeSetBonus.spawnSlime(self)
  local rand = math.random(2)
  local slimeType = nil
  if (rand == 2) then
    slimeType = "slimespawned"
  else
    slimeType = "microslimespawned"
  end
  local parameters = {
    persistent = false,
    damageTeamType = "friendly",
    aggressive = true,
    damageTeam = 0,
    level = self:getThreatLevel()
  }
  --sb.logInfo("spawning monster: type %s, level %s", slimeType, tostring(self:getThreatLevel()))
  world.spawnMonster(slimeType, mcontroller.position(), parameters)
end

--============================= CLASS EXTENSIONS ============================--
--[[ Any methods which need to be overridden from fuSetBonusBase should be
    defined in this section. ]]--

--[[ NOTE: When calling parent methods, use the syntax
        self.parent.method(self)
    rather than the conventional "syntactic sugar version"
        self.parent:method()
    The latter will pass the parent class as the "self" parameter, preventing
    any attributes overwritten by the child from being used. ]]--

function SlimeSetBonus.init(self)
  self.parent.init(self)
  -- Set up parameters for spawning slimes.
  self.spawnDelayBase = config.getParameter("spawnDelayBase")
  self.spawnDelayRange = config.getParameter("spawnDelayRange")
  self.spawnTimer = nil
  -- Set the slime spawn timer.
  self:resetSpawnTimer()
end

function SlimeSetBonus.update(self, dt)
  self.parent.update(self)
  self.spawnTimer = math.max(self.spawnTimer - dt, 0)
  if (self.spawnTimer == 0) then
    self:spawnSlime()
    self:resetSpawnTimer()
  end
end

--============================== INIT AND UNINIT =============================--
--[[ Starbound calls these non-class functions when handling status effects.
    They should not need to be modified (apart from the class name). ]]--

function init()
  SlimeSetBonus:init()
end

function uninit()
  SlimeSetBonus:uninit()
end

--=========================== MAIN UPDATE FUNCTION ==========================--
--[[ Starbound calls this non-class function when updating status effects. It
    shouldn't need to be modified (apart from the class name). ]]--

function update(dt)
  SlimeSetBonus:update(dt)
end

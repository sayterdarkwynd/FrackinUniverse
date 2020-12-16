incubation = {
  default = 1,
  primedegg = 1
}

function main()
  if entity.id() then
    local container = entity.id()
    local item = world.containerItemAt(container, 0)
    if canHatch(item) then
        if storage.incubationTime == nil then storage.incubationTime = os.time() end
        --TODO update time to config
        local hatchTime = incubation[item.name]
        if hatchTime == nil then hatchTime = incubation.default end
        local delta = os.time() - storage.incubationTime
        self.indicator = math.ceil( (delta / hatchTime) * 9)
        if delta >= hatchTime then
          hatchEgg()
          self.indicator = 0
        end

        if self.indicator == nil then self.indicator = 0 end
        if self.timer == nil or self.timer > self.indicator then self.timer = self.indicator - 1 end
        if self.timer > -1 then entity.setGlobalTag("bin_indicator", self.timer) end
        self.timer = self.timer + 1
    else
      storage.incubationTime = nil
    end
  end
end

function canHatch(item)
  if item == nil then return false end
  if item.name == "egg" then return true end
  if item.name == "raptoregg" then return true end
  return false
end

function hatchEgg()
  local container = entity.id()
  local item = world.containerTakeNumItemsAt(container, 0, 1)
  if item then
    if item.name == "egg" then
      local parameters = {}
      parameters.persistent = true
	  parameters.damageTeam = 0
      parameters.damageTeamType = "friendly"
      parameters.startTime = os.time()
      world.spawnMonster("chicken", entity.position(), parameters)
    elseif item.name == "raptoregg" then
      local parameters = {}
      parameters.persistent = true
	  parameters.damageTeam = 0
      parameters.damageTeamType = "friendly"
      parameters.startTime = os.time()
      world.spawnMonster("furaptor", entity.position(), parameters)
    end
  end
  storage.incubationTime = nil
end
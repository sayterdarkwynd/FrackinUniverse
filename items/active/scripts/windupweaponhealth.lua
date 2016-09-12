require "/scripts/util.lua"

local oldInit = init
local oldUpdate = update
local oldUnInit = uninit
local baseFireTime
local baseInaccuracy

function init()
  oldInit()
  baseProjectileCount = self.primaryAbility.projectileCount
  baseInaccuracy = self.primaryAbility.inaccuracy
  thing = 2
end

function update(dt, fireMode, shiftHeld)

  local scaleFactor = status.resource("energy") / status.resourceMax("energy") + 1 + thing
  self.primaryAbility.projectileCount = baseProjectileCount * scaleFactor
  self.primaryAbility.inaccuracy = baseInaccuracy * scaleFactor
  oldUpdate(dt, fireMode, shiftHeld)

end

function uninit()
  self.primaryAbility.projectileCount = baseProjectileCount
  self.primaryAbility.inaccuracy = baseInaccuracy
  oldUnInit()
end

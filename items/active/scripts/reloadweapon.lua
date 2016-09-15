require "/scripts/util.lua"

local oldInit = init
local oldUpdate = update
local oldUnInit = uninit

function init()
  oldInit()
end

function update(dt, fireMode, shiftHeld)
  local preEnergy = status.resource("energy")

  oldUpdate(dt, fireMode, shiftHeld)

  local postEnergy = status.resource("energy")

  if postEnergy < preEnergy and postEnergy == 0 then
    status.addEphemeralEffect("staffslow", 1.0)
  end
end

function uninit()
  oldUnInit()
end

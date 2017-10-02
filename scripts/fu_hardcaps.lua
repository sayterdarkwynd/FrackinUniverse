require "/scripts/vec2.lua"

function init()
  script.setUpdateDelta(60)
end


function update(dt)
   status.addEphemeralEffect("hardcapSet")  
end


function uninit()
  status.removeEphemeralEffect("hardcapSet")
end
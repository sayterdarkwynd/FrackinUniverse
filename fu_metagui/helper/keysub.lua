-- hmm.

local ipc = getmetatable ''.metagui_ipc
local ks = ipc.keysub
ks.accel = ks.accel or { }
local accel = ks.accel

local wid
function init()
  wid = player.worldId()
end

local lastDown
local keyRepeatTimer = 0

function update()
  if ipc.keysub ~= ks then return kill() end
  if player.worldId() ~= wid then return kill() end
  widget.focus("canvas")
  
  if lastDown then
    if keyRepeatTimer == 25 then
      ks.repeatEvent(lastDown, true, accel)
      keyRepeatTimer = keyRepeatTimer - 2
    else keyRepeatTimer = keyRepeatTimer + 1 end
  end
end

function keyEvent(key, down)
  if key >= 114 and key <= 121 then
    accel[key] = down or nil
    accel.shift = accel[114] or accel[115] or nil
    accel.ctrl = accel[116] or accel[117] or nil
    accel.alt = accel[118] or accel[119] or nil
    accel.meta = accel[120] or accel[121] or nil -- might as well
  elseif down then
    lastDown = key
    keyRepeatTimer = 0
  elseif key == lastDown then lastDown = nil end
  ks.keyEvent(key, down, accel)
end

local killed = false
function kill() killed = true pane.dismiss() end

function uninit()
  if not killed then -- assume esc pressed
    if ks.escEvent then ks.escEvent() end
  end
end

--

local mg = metagui

mg.keys = { -- dict of keycodes
  backspace = 0, del = 69,
  tab = 1, enter = 3, kpEnter = 85,
  home = 92, ["end"] = 93, pgUp = 94, pgDn = 95,
  up = 87, down = 88, left = 90, right = 89,
  numLock = 111, capsLock = 112, scrollLock = 113,
  menu = 123, prtSc = 125, sysRq = 125, pause = 127,
}

-- misc keys:
-- f1 etc. are 96 and on


local keychar = {
  [3] = {'\n', '\n'},
  [5] = {' ', ' '},
  [42] = {'`', '~'},
  [17] = {'-', '_'},
  [33] = {'=', '+'},
  [37] = {'[', '{'},
  [39] = {']', '}'},
  [38] = {'\\', '|'},
  [31] = {';', ':'},
  [11] = {'\'', '"'},
  [16] = {',', '<'},
  [18] = {'.', '>'},
  [19] = {'/', '?'},
  -- numpad
  [80] = {'.', '.'},
  [81] = {'/', '/'},
  [82] = {'*', '*'},
  [83] = {'-', '-'},
  [84] = {'+', '+'},
}

local numKey = ")!@#$%^&*("

function mg.keyToChar(k, accel)
  if type(accel) == "boolean" then accel = { shift = accel } end
  if keychar[k] then return keychar[k][accel.shift and 2 or 1] or keychar[k][1]
  elseif k >= 20 and k <= 29 then -- numbers
    if not accel.shift then return string.char(string.byte '0' + k - 20) end
    local i = k - 19
    return numKey:sub(i, i)
  elseif k >= 70 and k <= 79 then return string.char(string.byte '0' + k - 70) -- numpad
  elseif k >= 43 and k <= 68 then -- alphabet
    local ch = string.char(string.byte 'a' + k - 43)
    return accel.shift and ch:upper() or ch
  end
end

function mg.itemsCanStack(i1, i2)
  if not i1 and not i2 then return true elseif not i1 or not i2 then return false end
  if i1.name ~= i2.name then return false end
  return compare(i1.parameters, i2.parameters)
end

function mg.itemStacksToCursor(item)
  local stm = player.swapSlotItem()
  if not stm then return item.count end
  if not mg.itemsCanStack(item, stm) then return 0 end
  -- items can stack together, figure out how many
  local cfg = root.itemConfig(item)
  local maxStack = cfg.parameters.maxStack or cfg.config.maxStack or root.assetJson("/items/defaultParameters.config:defaultMaxStack")
  return math.min(maxStack - stm.count, item.count)
end

function mg.itemMaxStack(item)
  local cfg = root.itemConfig(item)
  return cfg.parameters.maxStack or cfg.config.maxStack or root.assetJson("/items/defaultParameters.config:defaultMaxStack")
end

function mg.fastCheckShift() -- check the fast way through tech hooks, fail if not available
  local p = world.sendEntityMessage(player.id(), "stardustlib:getTechInput")
  local r = p:succeeded() and p:result()
  if r then return r.key.sprint or false end
end

function mg.checkShift()
  local cr = coroutine.running()
  if not cr then sb.logWarn("metagui.checkShift() called in main thread!") return nil end
  
  -- try the fast route first
  local r = mg.fastCheckShift()
  if r ~= nil then return r end
  
  -- if no quick way is available, then fall back on the activeitem hack
  if player.isLounging() then return false end -- items disabled while lounging
  local icon = "/assetmissing.png"
  local stm = player.swapSlotItem()
  if stm then -- carry over icon
    local cfg = root.itemConfig(stm)
    icon = cfg.parameters.inventoryIcon or cfg.config.inventoryIcon or icon
    if type(icon) == "string" then icon = util.absolutePath(cfg.directory, icon)
    elseif type(icon) == "table" then -- composite icon
      icon = util.mergeTable({ }, icon) -- operate on copy
      for _, e in pairs(icon) do if e.image then e.image = util.absolutePath(cfg.directory, e.image) end end
    end
  end
  mg.ipc.shiftCheck = function(s) coroutine.resume(cr, 'sc', s) end
  player.setSwapSlotItem { name = "geode", count = stm and stm.count or 1, parameters = { inventoryIcon = icon, scripts = {mg.rootPath .. "helper/shiftstub.lua"}, restore = stm } }
  local chk, res = nil
  for i = 1,2 do
    chk, res = coroutine.yield()
    if chk == 'sc' then break end
  end
  if chk ~= 'sc' then -- failure
    player.setSwapSlotItem(stm)
    res = false
  end
  mg.ipc.shiftCheck = nil -- clean up
  return res
end

do -- limit variable scope
  local synced = true -- assume sync on pane open
  local function syncPingEv(id)
    synced = false
    local p = world.sendEntityMessage(id, "") -- empty message ID for just an "are you there?" ping
    while not p:finished() do coroutine.yield() end
    synced = true
  end
  
  function mg.checkSync(resync, id)
    if not id then id = pane.sourceEntity() end -- default to attached if id not specified
    if not id then return true end -- nothing to sync
    if not synced then return false end
    if not resync then return true end -- don't force a resync if not told to
    mg.startEvent(syncPingEv, id)
    return true
  end
  
  function mg.waitSync(resync, id)
    if not id then id = pane.sourceEntity() end -- default to attached if id not specified
    if not id then return end -- nothing to sync
    while not synced do coroutine.yield() end
    if not resync then return end -- don't force a resync if not told to
    mg.startEvent(syncPingEv, id)
  end
end

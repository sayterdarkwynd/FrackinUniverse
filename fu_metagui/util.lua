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

function mg.checkShift()
  local cr = coroutine.running()
  if not cr then sb.logWarn("metagui.checkShift() called in main thread!") return nil end
  local icon = "/assetmissing.png"
  local stm = player.swapSlotItem()
  if stm then -- carry over icon
    local cfg = root.itemConfig(stm)
    icon = util.absolutePath(cfg.directory, cfg.parameters.inventoryIcon or cfg.config.inventoryIcon or icon)
  end
  mg.ipc.shiftCheck = function(s) coroutine.resume(cr, 'sc', s) end
  player.setSwapSlotItem { name = "geode", count = stm and stm.count or 1, parameters = { inventoryIcon = icon, scripts = {mg.rootPath .. "helper/shiftstub.lua"}, restore = stm } }
  local chk, res = nil
  while chk ~= 'sc' do chk, res = coroutine.yield() end
  mg.ipc.shiftCheck = nil -- clean up
  return res
end

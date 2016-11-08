-- TODO - Terminal edition
-- DONE add description(? category?), distinct request buttons (1, 10, 100, 1000 should be fine I guess)
-- DONE doubleclick to grab a stack
-- DONE of course, finish the visual redesign
-- rarity desplay on selection?
-- maybe more sorting modes
-- variable color for on-icon count (maybe red being in the millions? *shrug*)
-- ...search additions? @category etc.

require "/scripts/vec2.lua"

require "/lib/stardust/sync.lua"
require "/lib/stardust/itemutil.lua"
require "/scripts/StarTech/tooltip.lua"

gridSize = 24
gridSpace = 25
gridWidth = 8 -- Royal~Jelly Changed max to 9 

if false then -- testing probe
  setmetatable(_ENV, { __index = function(t,k)
    sb.logInfo("missing field "..k.." accessed")
    local f = function(...)
      sb.logInfo("called")
    end
    return nil -- f
  end })
end

function init()
  items = {}
  itemUpdateId = "NaN"
  shownItems = {}
  selectedItem = {}
  selectedId = -1
  itemButtons = {}
  lastLayerSel = ""
  rows = {}
  rowInd = {}
  search = ""
  searchTime = 0
  updateTime = 0
  doubleClickTime = 0
  heartbeatTime = 0
  
  pid = pane.playerEntityId()
  sync.msg("playerOpen", pid)
end

function update()
  --
  
  updateTime = updateTime - 1
  if updateTime <= 0 then updateItemList() end
  searchTime = searchTime - 1
  if searchTime == 0 then refreshDisplay() end
  doubleClickTime = doubleClickTime - 1
  
  heartbeatTime = heartbeatTime - 1
  if heartbeatTime <= 0 then
    sync.msg("playerHeartbeat", pid)
    heartbeatTime = math.floor(60 * 0.1)
  end
  
  sync.runQueue()
  
  local startInd = widget.getListSelected("grid.list")
  if startInd then
    startInd = rowInd[startInd]
    for i = startInd, startInd+gridWidth-1 do
      local btn = itemButtons[i]
      if not btn then break end -- out of items
      local lsel = widget.getListSelected(btn)
      if lsel and lsel ~= lastLayerSel then
        lastLayerSel = lsel
        
        
        if i == selectedId and doubleClickTime > 0 then
          request() -- request a stack
        end
        selectItem(i)
        
        doubleClickTime = 15
        widget.blur("searchBox") -- unfocus search bar on selection
      end
    end
  end
  
end

function uninist()
  dismissed()
end
function dismissed() --uninit()
  sync.msg("playerClose", pid)
end

function btnExpandInfo() setExpandedInfo() end
infoExpanded = false
function setExpandedInfo(setting)
  if setting == nil then setting = not infoExpanded end
  infoExpanded = setting
  
  local btnImg = "/interface/tech/storagenet/buttons/expandinfo.png"
  
  if setting then
    widget.setSize("selItem_description", { 322, 152 })
    widget.setPosition("expandedinfocover", { 0, 0 })
    widget.setPosition("selItem_label", { 42, 162 })
    
    btnImg = btnImg .. "?flipy"
  else
    widget.setSize("selItem_description", { 322, 33 })
    widget.setPosition("expandedinfocover", { 5730, 0 })
    widget.setPosition("selItem_label", { 42, 42 })
  end
  
  widget.setButtonImages("expandinfo", {
    base = btnImg .. "?replace;ffffff=bfbfbf",
    hover = btnImg
  })
end

function selectItem(i, updating)
  setExpandedInfo(false)
  if i < 0 then -- -1 == blank
    selectedItem = {}
    selectedId = -1 -- hmm. I wonder..
    widget.clearListItems("selItem_icon")
  
    widget.setText("selItem_label", "")
    widget.setText("selItem_description.text", "")
    return nil
  end
  if not updating and selectedId >= 0 then
    applyIcon(selectedItem, itemButtons[selectedId], true) -- visibly deselect
  end
  selectedItem = shownItems[i]
  if not updating then 
    if selectedId >= 0 then applyIcon(shownItems[selectedId], itemButtons[selectedId], true) end -- visibly deselect
    applyIcon(selectedItem, itemButtons[i], true) -- immediately reflash icon to selected
  end 
  selectedId = i
  applyIcon(selectedItem, "selItem_icon")
  
  local conf = getConf(selectedItem)
  
  widget.setText("selItem_label", table.concat({ selectedItem.parameters.shortdescription or conf.config.shortdescription, " ^#7fffff;(x", selectedItem.count, ")" }))
  --if not updating then widget.setText("selItem_description.text", "") end -- try to reset scroll height
  
  local addInfo = ""
  if conf.config.itemTags and conf.config.itemTags[1] == "weapon" then
    addInfo = tooltip.weaponInfo(selectedItem, nil, "\n")
  end
  
  widget.setText("selItem_description.text", table.concat({
    selectedItem.parameters.description or conf.config.description,
    addInfo
  }))
  --sb.logInfo(sb.printJson(root.itemConfig(selectedItem)))
end

function updateItemList()
  sync.poll("updateItems", onRecvItemList, itemUpdateId)
  updateTime = math.floor(60*0.5)
end

local requestBtn = {
  req1 = 1,
  req10 = 10,
  req100 = 100,
  req1000 = 1000
}
function request(btn)
  if not selectedItem.name then return nil end -- no item selected!
  sync.poll("request", updateItemList(), {
    name = selectedItem.name,
    count = math.min(requestBtn[btn] or 1000, selectedItem.parameters.maxStack or getConf(selectedItem).config.maxStack or 1000),
    parameters = selectedItem.parameters
  }, pane.playerEntityId())
end

function onRecvItemList(rpc)
  if not rpc:succeeded() then return nil end
  local rItems, rUid = rpc:result()
  if not rItems then return nil end
  items = rItems
  itemUpdateId = rUid -- TODO: FIX THIS
  refreshDisplay()
end

function refresh()
  -- doop de doo
  local lpos = widget.getPosition("grid.list")
  widget.setPosition("grid.list", {lpos[1] + 2, lpos[2]})
end

function searchBox()
  search = string.lower(widget.getText("searchBox"))
  --refreshDisplay()
  searchTime = 5 -- avoid clobbering with lag
end
function searchBoxEsc()
  widget.blur("searchBox")
end
function searchBoxEnter()
  widget.blur("searchBox")
end

function refreshDisplay()
  shownItems = {}
  local i = 1
  if search == "" then
    for k,v in pairs(items) do
      shownItems[i] = v
      i = i + 1
    end
  elseif search:sub(1, 2) == "/ " then
    local filter = search:sub(3)
    for k,v in pairs(items) do
      if itemutil.matchFilter(filter, v) then
        shownItems[i] = v
        i = i + 1
      end
    end
  else
    for k,v in pairs(items) do
      if string.find(string.lower(v.parameters.shortdescription or root.itemConfig(v).config.shortdescription), search) then
        shownItems[i] = v
        i = i + 1
      end
    end
  end
  
  table.sort(shownItems, itemSortByCount)
  buildList()
end

function buildList()
  rows = {}
  rowInd = {}
  itemButtons = {}
  widget.clearListItems("grid.list")
  
  local count = #shownItems
  
  local foundSel = false
  
  local gy, gx = 0, 9
  while true do
    if gx > gridWidth then
      gx = 1
      gy = gy + 1
      local i = (gy - 1) * gridWidth + gx -- v
      if i > count then break end -- Avoid empty extra line at the bottom with an even multiple of gridWidth item slots
      local li = widget.addListItem("grid.list")
      rowInd[li] = 1 + (gy - 1) * gridWidth
      rows[gy] = "grid.list." .. li
    end
    --
    local i = (gy - 1) * gridWidth + gx
    if i > count then break end
    
    if selectedItem.name and itemutil.canStack(selectedItem, shownItems[i]) then selectedItem = shownItems[i] foundSel = true end -- preserve selection
    
    local pfx = table.concat({ rows[gy], ".s", gx })
    local icon = table.concat({ pfx, "-icon" })
    itemButtons[i] = icon
    local icount = table.concat({ pfx, "-count" })
    widget.setPosition(icon, {gridSpace * (gx - 1), gridSize} )
    applyIcon(shownItems[i], icon, true)
    widget.setPosition(icount, {gridSpace * (gx - 1) + (gridSpace - 2), 0} )
    widget.setText(icount, prettyCount(shownItems[i].count or 1))
    
    gx = gx + 1
  end
  
  if not foundSel then selectItem(-1) end
end

function prettyCount(num)
  if num < 1 then return "craft"
  elseif num > 999999999 then return math.floor(num / 1000000000) .. "B"
  elseif num > 999999 then return math.floor(num / 1000000) .. "M"
  elseif num > 9999 then return math.floor(num / 1000) .. "K"
  end
  return "" .. num
  
end

function applyIcon(item, wid, doFrame)
  if not wid then return nil end -- apparently this can happen
  widget.clearListItems(wid) -- because reinit
  
  local conf = getConf(item) -- root.itemConfig(item)
  
  if doFrame then
    local xicon = "/interface/tech/storagenet/itemSlot.png"
    if item == selectedItem then xicon = "/interface/tech/storagenet/itemSlot.selected.png" end
    local layer = table.concat({ wid, ".", widget.addListItem(wid), ".icon" })
    widget.setImage(layer, xicon)
    
    layer = table.concat({ wid, ".", widget.addListItem(wid), ".icon" })
    widget.setImage(layer, table.concat({ "/interface/tech/storagenet/itemSlot.rarity.", (item.parameters.rarity or conf.config.rarity or "common"):lower(), ".png" }))
  end
    
	local icon = item.parameters.inventoryIcon or conf.config.inventoryIcon or conf.config.codexIcon
  
  local addColor = ""
  local colorOpt = item.parameters.colorOptions or conf.config.colorOptions
  if colorOpt then
    local colordef = colorOpt[(item.parameters.colorIndex or 0)+1]
    if colordef then
      local cb, i = {"?replace"}, 2
      for k,v in pairs(colordef) do
        cb[i] = ";"
        cb[i+1] = k
        cb[i+2] = "="
        cb[i+3] = v
        i = i + 4
      end
      cb[i] = item.parameters.directives -- might as well bake this in here
      addColor = table.concat(cb)
    end
  end
  
  if icon ~= nil and type(icon) == "string" then
    icon = {{image = icon}}
  end
  if icon ~= nil and type(icon) == "table" then
    local scale = 1
    local bounds = { 1000, 1000, 0, 0 }
    -- precalc stuff
    for i,v in pairs(icon) do
      local xicon = absolutePath(conf.directory, v.image)
      local ipos = v.position or {0,0}
      ipos = { ipos[1] * 0.75, ipos[2] * 0.75 } -- super silly hack, but it seems to fix guns being in pieces so ???
      local ibounds = root.nonEmptyRegion(xicon) or {0,0,0,0}
      
      -- take offsets into account
      ibounds[1] = ibounds[1] + ipos[1]
      ibounds[2] = ibounds[2] + ipos[2]
      ibounds[3] = ibounds[3] + ipos[1]
      ibounds[4] = ibounds[4] + ipos[2]
      
      bounds[1] = math.min(bounds[1], ibounds[1])
      bounds[2] = math.min(bounds[2], ibounds[2])
      bounds[3] = math.max(bounds[3], ibounds[3])
      bounds[4] = math.max(bounds[4], ibounds[4])
    end
    
    scale = math.min(scale, (gridSize) / (bounds[3] - bounds[1]))
    scale = math.min(scale, (gridSize) / (bounds[4] - bounds[2]))
    
    local offset = {
      (gridSize / 2 - ((bounds[3] - bounds[1]) * scale) / 2 - bounds[1] * scale),
      (gridSize / 2 - ((bounds[4] - bounds[2]) * scale) / 2 - bounds[2] * scale)
    }
    
    for i,v in pairs(icon) do
      local xicon = absolutePath(conf.directory, v.image) .. addColor
      local layer = table.concat({ wid, ".", widget.addListItem(wid), ".icon" })
      widget.setImage(layer, xicon)
      widget.setImageScale(layer, scale)
      local ipos = v.position or {0,0}
      ipos = { ipos[1] * 0.75, ipos[2] * 0.75 } -- don't modify original
      ipos[1] = (offset[1] + (ipos[1] * scale))
      ipos[2] = (offset[2] + (ipos[2] * scale))
      widget.setPosition(layer, ipos)
    end
  end
end

function absolutePath(directory, path)
  if type(path) ~= "string" then
  	return false;
  end
  if string.sub(path, 1, 1) == "/" then
    return path
  else
    return directory..path
  end
end


function dump(o, ind)
  if not ind then ind = 2 end
  local pfx, epfx = "", ""
  for i=1,ind do pfx = pfx .. " " end
  for i=3,ind do epfx = epfx .. " " end
  if type(o) == 'table' then
    local s = '{\n'
    for k,v in pairs(o) do
      if type(k) ~= 'number' then k = '"'..k..'"' end
      s = s .. pfx .. '['..k..'] = ' .. dump(v, ind+2) .. ',\n'
    end
    return s .. epfx .. '}'
  else
    return tostring(o)
  end
end

-- moved into itemutil :D
getConf = itemutil.getCachedConfig

function itemSortByCount(i1, i2)
  local c1, c2 = getConf(i1), getConf(i2) -- root.itemConfig(i1), root.itemConfig(i2)
  if i1.count ~= i2.count then return i1.count > i2.count end -- > because most-first
  local n1, n2 = i1.parameters.shortdescription or c1.config.shortdescription, i2.parameters.shortdescription or c2.config.shortdescription
	return n1 < n2; 
end

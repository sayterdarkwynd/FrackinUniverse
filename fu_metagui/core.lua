-- provider configuration
local MG_FALLBACK_PATH = "/metagui/themes/fallbackAssets/"

------------------
-- metaGUI core --
------------------

require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/scripts/rect.lua"

local function module(s) require(metagui.rootPath .. s .. ".lua") end -- for easy repointing if needed

local debug = {
  --showLayoutBoxes = true,
}

-- metaGUI core
metagui = metagui or { }
local mg = metagui
mg.rootPath = getmetatable ''.metagui_root
mg.debugFlags = debug

module "gfx"

function mg.path(path)
  if not path then return nil end
  if path:sub(1, 1) == '/' then return path end
  return (mg.cfg.assetPath or "/") .. path
end

function mg.asset(path)
  if not path then return nil end
  if path:sub(1, 1) == '/' then return path end
  local ext = path:match('^.*%.(.-)$')
  local op = mg.cfg.themePath .. path
  if ext == "png" and not root.nonEmptyRegion(op) then
    if theme and theme.fallback then
      for _, t in ipairs(theme.fallback) do
        local tp = mg.registry.themes[t]
        if tp then
          local p = tp .. path
          if root.nonEmptyRegion(p) then return p end
        end
      end
    end
    return MG_FALLBACK_PATH .. path
  end
  return op
end

do -- encapsulate
  local id = 0
  function mg.newUniqueId()
    id = id + 1
    return tostring(id)
  end
end

function mg.mkwidget(parent, param)
  local id = mg.newUniqueId()
  if not parent then
    pane.addWidget(param, id)
    return id
  end
  widget.addChild(parent, param, id)
  return table.concat{ parent, '.', id }
end

local getproto do
  local pt = { }
  getproto = function(parent)
    if not pt[parent] then
      pt[parent] = { __index = parent }
    end
    return pt[parent]
  end
  function mg.proto(parent, table) return setmetatable(table or { }, getproto(parent)) end
end

-- some operating variables
local redrawQueue = { }
local recalcQueue = { }
local lastMouseOver
local mouseMap = setmetatable({ }, { __mode = 'v' })
local scriptUpdate, scriptUninit = { }, { }

-- define event queue before widgets
local eventQueue = { }
local function runEventQueue()
  local next = { }
  for _, v in pairs(eventQueue) do
    if coroutine.status(v) ~= "dead" then -- precheck; coroutine may have finished outside via IPC
      local f, err = coroutine.resume(v)
      if coroutine.status(v) ~= "dead" then table.insert(next, v) -- execute; insert in next-frame queue if still running
      elseif not f then sb.logError(err) end
    end
  end
  eventQueue = next
  theme.update()
  for _, f in pairs(scriptUpdate) do f() end
end
function mg.startEvent(func, ...)
  local c = coroutine.create(func)
  local f, err = coroutine.resume(c, ...)
  if coroutine.status(c) ~= "dead" then table.insert(eventQueue, c)
  elseif not f then sb.logError(err) end
  return c -- might as well
end

-- and widget stuff
mg.widgetTypes = { }
mg.widgetBase = {
  expandMode = {0, 0}, -- default: decline to expand in either direction (1 is "can", 2 is "wants to")
  visible = true,
}
local widgetTypes, widgetBase = mg.widgetTypes, mg.widgetBase

function widgetBase:minSize() return {0, 0} end
function widgetBase:preferredSize() return {0, 0} end

function widgetBase:center() return vec2.add(self.position, vec2.mul(self.size, 0.5)) end

function widgetBase:init() end

function widgetBase:queueRedraw() redrawQueue[self] = true end
function widgetBase:draw() end

function widgetBase:isMouseInteractable() return false end
function widgetBase:isWheelInteractable() return false end
function widgetBase:onMouseEnter() end
function widgetBase:onMouseLeave() end
function widgetBase:onMouseButtonEvent(btn, down) end
function widgetBase:onMouseWheelEvent(dir) end
function widgetBase:isMouseOver() return self == lastMouseOver end

function widgetBase:captureMouse(btn) return mg.captureMouse(self, btn) end
function widgetBase:releaseMouse() return mg.releaseMouse(self) end
function widgetBase:hasMouse() return mg.hasMouse(self) end
function widgetBase:mouseCaptureButton() return mg.mouseCaptureButton(self) end
function widgetBase:mouseCapturePoint() return mg.mouseCapturePoint(self) end
function widgetBase:onCaptureMouseMove() end
function widgetBase:canPassMouseCapture() end
function widgetBase:onPassedMouseCapture() end
function widgetBase:passMouseCapture(w) -- pass to nearest accepting ancestor
  if not mg.hasMouse(self) then return nil end
  if not w then
    w = self.parent
    while w and not w:canPassMouseCapture() do w = w.parent end
  end
  if w then
    local pt = self:mouseCapturePoint()
    w:captureMouse(self:mouseCaptureButton())
    w:onPassedMouseCapture(pt)
    return true
  end
end

function widgetBase:relativeMousePosition() return mg.paneToWidgetPosition(self, mg.mousePosition) end
function widgetBase:relativePanePosition(pos) return mg.paneToWidgetPosition(self, pos) end
function widgetBase:relativeScreenPosition(pos) return mg.screenToWidgetPosition(self, pos) end

function widgetBase:getToolTip() return self.toolTip or nil end

function widgetBase:grabFocus() return mg.grabFocus(self) end
function widgetBase:releaseFocus() return mg.releaseFocus(self) end
function widgetBase:onFocus() end
function widgetBase:onUnfocus() end
function widgetBase:onKeyEvent(key, down) end
function widgetBase:onKeyEsc() end
function widgetBase:acceptsKeyRepeat() end

function widgetBase:applyGeometry(selfOnly)
  self.size = self.size or self:preferredSize() -- fill in default size if absent
  local tp = self.position or {0, 0}
  local s = self
  while s.parent and not s.parent.isBaseWidget do
    tp = vec2.add(tp, s.parent.position or {0, 0})
    s = s.parent
  end
  s = s.parent -- we want the parent of the result
  -- apply calculated total position
  --sb.logInfo("processing " .. (self.backingWidget or "unknown") .. ", type " .. self.typeName)
  local etp
  if self.parent then etp = { tp[1], s.size[2] - (tp[2] + self.size[2]) } else etp = tp end -- if no parent, it must be a backing widget
  if not self.visible then etp = {-99999, -99999} end -- simulate invisibility by shoving way offscreen
  if self.backingWidget then
    widget.setSize(self.backingWidget, {math.floor(self.size[1]), math.floor(self.size[2])})
    widget.setPosition(self.backingWidget, {math.floor(etp[1]), math.floor(etp[2])})
  end
  --sb.logInfo("widget " .. (self.backingWidget or "unknown") .. ", type " .. self.typeName .. ", pos (" .. self.position[1] .. ", " .. self.position[2] .. "), size (" .. self.size[1] .. ", " .. self.size[2] .. ")")
  self:queueRedraw()
  if not selfOnly and self.children then
    for k,c in pairs(self.children) do
      if c.applyGeometry then c:applyGeometry() end
    end
  end
end

function widgetBase:queueGeometryUpdate() -- find root
  local w = self
  while w.parent do w = w.parent end
  recalcQueue[w] = true
end
function widgetBase:updateGeometry() end
function widgetBase:setVisible(v) self.visible = v self:queueGeometryUpdate() end

function widgetBase:addChild(param) return mg.createWidget(param, self) end
function widgetBase:clearChildren()
  local c = { }
  for _, v in pairs(self.children or { }) do table.insert(c, v) end
  for _, v in pairs(c) do v:delete() end
end
function widgetBase:delete()
  widgetBase.clearChildren(self) -- clear down first
  if self.parent then -- remove from parent
    for k, v in pairs(self.parent.children) do
      if v == self then table.remove(self.parent.children, k) break end
    end
    self.parent:queueGeometryUpdate()
  end
  local ctx = self.widgetContext or _ENV
  if self.id and ctx[self.id] == self then ctx[self.id] = nil end -- remove from global
  self.deleted = true
  
  -- unhook from events and drawing
  redrawQueue[self] = nil
  recalcQueue[self] = nil
  if lastMouseOver == self then lastMouseOver = nil end
  self:releaseMouse()
  
  -- clear out backing widgets
  local function rw(w)
    local parent, child = w:match('^(.*)%.(.-)$')
    widget.removeChild(parent, child)
  end
  if self.backingWidget then rw(self.backingWidget) end
  if self.subWidgets then for _, sw in pairs(self.subWidgets) do rw(sw) end end
end

-- find parent of specific widget type
function widgetBase:findParent(wtype)
  local p = self
  while p.parent do p = p.parent
    if p.widgetType == wtype then return p end
  end
end

-- event subscription stuff
function widgetBase:subscribeEvent(ev, f)
  self.__event = self.__event or { }
  self.__event[ev] = f
end
function widgetBase:pushEvent(ev, ...)
  if self.__event then
    local e = self.__event[ev]
    if e then
      local ret = {e(self, ...)}
      if ret[1] then return table.unpack(ret) end -- return a truthy value to "catch"
    end
  end
  -- else pass to children
  for _,c in pairs(self.children or { }) do
    local ret = {c:pushEvent(ev, ...)}
    if ret[1] and ret[1] ~= true then return table.unpack(ret) end -- only nonboolean values short-circuit!
  end
end
function widgetBase:broadcast(ev, ...) return self.parent:pushEvent(ev, ...) end -- just a quick shortcut
function widgetBase:wideBroadcast(levels, ev, ...) -- broadcast up a number of levels
  local w = self
  for i = 1, levels do
    if not w.parent then break end
    w = w.parent
  end
  return w:pushEvent(ev, ...)
end

module "widgets"

-- populate type names
for id, t in pairs(widgetTypes) do t.widgetType = id end

function mg.createWidget(param, parent)
  if not param or not param.type or not widgetTypes[param.type] then return nil end -- abort if not valid
  local w = mg.proto(widgetTypes[param.type])
  if parent then -- add as child
    w.parent = parent
    w.parent.children = w.parent.children or { }
    table.insert(w.parent.children, w)
    parent:queueGeometryUpdate()
  end
  
  -- some basics
  w.id = param.id
  w.position = param.position or {0, 0}
  w.explicitSize = param.size
  w.size = param.size or {0, 0}
  if param.visible ~= nil then w.visible = param.visible end
  w.toolTip = param.toolTip
  w.data = param.data -- arbitrary build-time data
  
  local base
  if parent then -- find base widget
    local f = parent
    while not f.isBaseWidget and f.parent do f = f.parent end
    base = f.backingWidget
  end
  w:init(base, param)
  
  -- enroll in mouse events
  if w.backingWidget then mouseMap[w.backingWidget] = w end
  if w.subWidgets then for _, sw in pairs(w.subWidgets) do mouseMap[sw] = w end end
  
  -- assign id
  w.widgetContext = mg.widgetContext
  local ctx = w.widgetContext or _ENV
  if w.id and ctx[w.id] == nil then
    ctx[w.id] = w
  end
  return w
end

function mg.createImplicitLayout(list, parent, defaults)
  list = list or { }
  local p = { type = "layout", children = list }
  if parent then -- inherit some defaults off parent
    if parent.mode == "horizontal" then p.mode = "vertical"
    elseif parent.mode == "vertical" then p.mode = "horizontal"
    elseif parent.mode == "stack" then
      p.mode = "horizontal"
      p.expandMode = {2, 2}
    end
    p.spacing = parent.spacing
  end
  
  if defaults then util.mergeTable(p, defaults) end
  if type(list[1]) == "table" and not list[1][1] and not list[1].type then util.mergeTable(p, list[1]) end
  return mg.createWidget(p, parent)
end

local redrawFrame = { draw = function() theme.drawFrame() end }
function mg.queueFrameRedraw() redrawQueue[redrawFrame] = true end
function mg.setTitle(s)
  mg.cfg.title = s
  mg.queueFrameRedraw()
end
function mg.setIcon(img)
  mg.cfg.icon = mg.path(img)
  mg.queueFrameRedraw()
end

local mouseCaptor, mouseCaptureBtn, mouseCapturePoint
function mg.captureMouse(w, btn)
  if w ~= mouseCaptor then
    mouseCaptor, mouseCaptureBtn, mouseCapturePoint = w, btn, mg.mousePosition
    return true
  end
end
function mg.releaseMouse(w) if w == mouseCaptor or not w then mouseCaptor = nil return true end end
function mg.mouseCaptureButton(w) if mouseCaptor and (w == mouseCaptor or not w) then return mouseCaptureBtn end end
function mg.mouseCapturePoint(w) if mouseCaptor and (w == mouseCaptor or not w) then return mouseCapturePoint end end
function mg.hasMouse(w) return w == mouseCaptor end

function mg.screenToWidgetPosition(w, pos) return mg.paneToWidgetPosition(w, vec2.sub(pos, mg.windowPosition)) end
function mg.paneToWidgetPosition(w, pos)
  pos = vec2.mul(pos, {1, -1}) -- make screen-relative and pre-invert
  while w do
    if not w.parent then -- root widget
      pos[1] = pos[1] - w.position[1]
      pos[2] = pos[2] + w.size[2] + w.position[2] - 1 -- compensate for reported position oddness
    else
      pos = vec2.sub(pos, w.position)
    end
    w = w.parent
  end
  return pos
end

local function spawnKeysub(respawn)
  if not respawn and mg.ipc.keysub and mg.ipc.keysub.master == mg then return nil end
  mg.ipc.keysub = { keyEvent = _keyEvent, repeatEvent = _keyRepeatEvent, escEvent = _keyEscEvent, master = mg, accel = mg.ipc.keysub and mg.ipc.keysub.accel or nil }
  player.interact("ScriptPane", {
    gui = { canvas = { type = "canvas", captureKeyboardEvents = true } },
    canvasKeyCallbacks = { canvas = "keyEvent" },
    scripts = {mg.rootPath .. "helper/keysub.lua"}
  }, 0)
end
local function killKeysub()
  if mg.ipc.keysub and mg.ipc.keysub.master == mg then
    mg.ipc.keysub = nil
  end
end

local keyFocus
function mg.grabFocus(w)
  if w ~= keyFocus then
    if keyFocus then keyFocus:onUnfocus() end
    keyFocus = w
    if keyFocus then keyFocus:onFocus() end
  end
  if not keyFocus then killKeysub()
  elseif w then spawnKeysub(true) end
end
function mg.releaseFocus(w) if w == keyFocus or w == true then mg.grabFocus(nil) return true end end

function mg.broadcast(ev, ...) paneBase:pushEvent(ev, ...) frame:pushEvent(ev, ...) end

-- register an action on pane close
function mg.registerUninit(f) if type(f) == "function" then table.insert(scriptUninit, f) end end

module "util"
module "extra"

-- -- --

local wheel = { }
local worldId
function init() -------------------------------------------------------------------------------------------------------------------------------------
  -- guard against wonky reloads
  if widget.getData("_tracker") then return pane.dismiss() end
  widget.setData("_tracker", "open")
  
  mg.registry = root.assetJson("/metagui/registry.json")
  mg.cfg = config.getParameter("___") -- window config
  mg.inputData = mg.cfg.inputData -- alias
  
  mg.settings = player.getProperty("metagui:settings") or player.getProperty("metaGUISettings") or { }
  
  mg.theme = root.assetJson(mg.cfg.themePath .. "theme.json")
  mg.theme.id = mg.cfg.theme
  mg.theme.path = mg.cfg.themePath
  _ENV.theme = mg.theme -- alias
  module "theme-common" -- load theme defaults and common utils
  require(mg.theme.path .. "theme.lua") -- load in theme
  
  mg.cfg.icon = mg.path(mg.cfg.icon) -- pre-resolve icon path
  
  -- TODO set up some parameter stuff?? idk, maybe the theme does most of that
  
  -- store this for later
  worldId = player.worldId()
  
  -- set up IPC
  do local mt = getmetatable ''
    mt.metagui_ipc = mt.metagui_ipc or { }
    mg.ipc = mt.metagui_ipc
  end
  
  if mg.cfg.uniqueBy == "path" and mg.cfg.configPath then
    mg.ipc.uniqueByPath = mg.ipc.uniqueByPath or { }
    mg.ipc.uniqueByPath[mg.cfg.configPath] = function() pane.dismiss() end
  end
  
  -- set up basic pane stuff
  local borderMargins = mg.theme.metrics.borderMargins[mg.cfg.style]
  frame = mg.createWidget({ type = "layout", size = mg.cfg.totalSize, position = {0, 0}, zlevel = -9999 })
  paneBase = mg.createImplicitLayout(mg.cfg.children, nil, { size = mg.cfg.size, position = {borderMargins[1], borderMargins[4]}, mode = mg.cfg.layoutMode or "vertical" })
  
  do -- set up scrollwheel test assembly
    wheel.base = "_wheel"
    wheel.target = "_wheel.w.target"
    wheel.over = "_wheel.w.over"
    wheel.offset = {0, 0}
    function wheel.block(t)
      local se = not wheel.disabled
      wheel.disabled = math.max(wheel.disabled or 0, t or 15)
      if se then
        mg.startEvent(function()
          while wheel.disabled and wheel.disabled > 0 do
            wheel.disabled = wheel.disabled - 1
            coroutine.yield()
          end
          wheel.disabled = nil
        end)
      end
    end
    --wheel.block() -- start blocked so it doesn't misfire the first few frames
    local size = mg.cfg.totalSize
    wheel.proto = {
      type = "scrollArea", position = {0, 0}, size = size, verticalScroll = false, children = {
        fill = { type = "widget", position = {0, 0}, size },
        target = { type = "widget", position = wheel.offset, size = {size[1], 72} },
        over = { type = "widget", position = wheel.offset, size = {size[1], 1000} },
      }
    }
  end
  
  mg.theme.decorate()
  mg.theme.drawFrame()
  
  local sysUpdate, sysUninit = update, uninit
  for _, s in pairs(mg.cfg.scripts or { }) do
    init, update, uninit = nil
    require(mg.path(s))
    if update then table.insert(scriptUpdate, update) end
    if uninit then table.insert(scriptUninit, uninit) end
    if init then init() end -- call script init
  end
  update, uninit = sysUpdate, sysUninit
  
  frame:updateGeometry()
  paneBase:updateGeometry()
  for w in pairs(redrawQueue) do if not w.deleted then w:draw() end end
  recalcQueue, redrawQueue = { }, { }
  
  --setmetatable(_ENV, {__index = function(_, n) if DBG then DBG:setText("unknown func " .. n) end end})
end

local function recreateWheelChild()
  if mg.windowPosition[2] < 0 then
    wheel.offset[2] = -mg.windowPosition[2]
  else
    wheel.offset[2] = 0
  end
  
  widget.removeChild(wheel.base, "w")
  widget.addChild(wheel.base, wheel.proto, "w")
  wheel.created = true
end
local function setWheelActive(b)
  if b ~= nil then wheel.active = not not b end
  widget.setPosition(wheel.base, {wheel.active and 0 or 99999999, 0})
  if not wheel.created then
    recreateWheelChild()
  end
end

function uninit()
  killKeysub()
  for _, f in pairs(scriptUninit) do f() end
  if mg.ipc.uniqueByPath and mg.cfg.configPath then mg.ipc.uniqueByPath[mg.cfg.configPath] = nil end
  if mg.cfg.isContainer then mg.ipc.openContainerProxy = nil end
end

local function findWindowPosition()
  if not mg.windowPosition then mg.windowPosition = {0, 0} end -- at the very least, make sure this exists
  local fp
  local sz = mg.cfg.totalSize
  local max = {1920, 1080} -- technically probably 4k
  
  local ws = "_tracker" -- widget to search for
  
  -- initial find
  for y=0,max[2],sz[2] do
    for x=0,max[1],sz[1] do
      if widget.inMember(ws, {x, y}) then
        fp = {x, y} break
      end
    end
    if fp then break end
  end
  
  if not fp then return nil end -- ???
  
  local isearch = 32
  -- narrow x
  local search = isearch
  while search >= 1 do
    while widget.inMember(ws, {fp[1] - search, fp[2]}) do fp[1] = fp[1] - search end
    search = search / 2
  end
  
  -- narrow y
  local search = isearch
  while search >= 1 do
    while widget.inMember(ws, {fp[1], fp[2] - search}) do fp[2] = fp[2] - search end
    search = search / 2
  end
  
  mg.windowPosition = fp
  mg.windowOffScreen = not widget.inMember(ws, vec2.add(fp, mg.cfg.totalSize))
  wheel.block()
  --pane.playSound("/sfx/interface/hoverover_bumb.ogg", 0, 0.75)
end

mg.mousePosition = {0, 0} -- default

local bcv = { "_tracker", "_mouse" }
local bcvmp = { {0, 0}, {0, 0} } -- last saved mouse position

function update()
  if player.worldId() ~= worldId then return pane.dismiss() end
  
  if not mg.windowPosition then findWindowPosition() else
    if mg.windowOffScreen then
      -- for now, trust the cursor?
    else -- autocheck
      if not widget.inMember(bcv[1], {math.max(0, mg.windowPosition[1]), math.max(0, mg.windowPosition[2])})
      or not widget.inMember(bcv[1], vec2.add(mg.windowPosition, mg.cfg.totalSize)) then findWindowPosition() end
    end
  end
  
  local wheelDir
  if wheel.disabled then
    recreateWheelChild()
  elseif wheel.active then
    local pt = vec2.add(mg.windowPosition, wheel.offset)
    pt[1] = math.max(0, pt[1]) pt[2] = math.max(0, pt[2]) -- limit to screen
    local bpf = widget.inMember("_wheel.w", pt)
    local pf = pt[2] < 0 or widget.inMember(wheel.target, pt)
    if not bpf then
      --recreateWheelChild()
    elseif not pf then
      if widget.inMember(wheel.over, pt) then -- check overflow
        wheelDir = -1 -- scroll up
      else
        wheelDir = 1 -- scroll down
      end
    end
    if wheelDir then recreateWheelChild() end
  end
  
  local lmp = mg.mousePosition
  -- we don't know which of these gets mouse changes properly, so we loop through and
  for k,v in pairs(bcv) do -- set the mouse position whenever one detects a change
    local bc = widget.bindCanvas(v)
    if bc then
      local mp = bc:mousePosition()
      if not vec2.eq(bcvmp[k], mp) then
        bcvmp[k] = mp
        mg.mousePosition = mp
        bcvmp[0] = true
      end
    end
  end
  
  runEventQueue() -- not entirely sure where this should go in the update cycle
  
  setWheelActive(false) -- yeet it out of the way so it doesn't hog getChildAt checks
  local mw = mouseCaptor
  if not mw then
    local mwc = widget.getChildAt(vec2.add(mg.windowPosition, mg.mousePosition))
    mwc = mwc and mwc:sub(2)
    while mwc and not mouseMap[mwc] do
      mwc = mwc:match('^(.*)%..-$')
    end
    if mwc then mw = mouseMap[mwc] end
    while mw and not mw:isMouseInteractable() do
      mw = mw.parent
    end
  end
  
  local ww = mw -- find wheel target
  if not mouseCaptor then
    while ww and not ww:isWheelInteractable() do
      ww = ww.parent
    end
  end
  
  if mw ~= lastMouseOver then
    if mw then mw:onMouseEnter() end
    if lastMouseOver then lastMouseOver:onMouseLeave() end
  end
  lastMouseOver = mw
  widget.setVisible(bcv[2], not not (mw or keyFocus))
  
  if mouseCaptor then -- send mouse move event
    mouseCaptor:onCaptureMouseMove(vec2.sub(mg.mousePosition, lmp))
  end
  
  if wheelDir then -- send mouse wheel event
    local w = ww
    while w and (not w:isWheelInteractable() or not w:onMouseWheelEvent(wheelDir)) do
      w = w.parent
    end
  end
  
  if ww then setWheelActive(true) end -- intercept mouse wheel whenever something wants it
  if keyFocus or mw then widget.focus(bcv[2])
  else widget.focus(bcv[1]) end
  
  local rdq, rcq = redrawQueue, recalcQueue
  redrawQueue, recalcQueue = { }, { }
  for w in pairs(rcq) do if not w.deleted then w:updateGeometry() end end
  for w in pairs(rdq) do if not w.deleted then w:draw() end end
  
  --
end

function cursorOverride(pos)
  if not bcvmp[0] then -- no registered mouse positions
    if mg.windowPosition then mg.mousePosition = vec2.sub(pos, mg.windowPosition) end
  else
    if mg.windowOffScreen then mg.windowPosition = vec2.sub(pos, mg.mousePosition) end -- compensate for partial offscreen
    --
  end
end

function createTooltip()
  if lastMouseOver then return mg.toolTip(lastMouseOver:getToolTip()) end
end

function _mouseEvent(_, btn, down)
  if lastMouseOver then
    local w = lastMouseOver
    while not w:isMouseInteractable() or not w:onMouseButtonEvent(btn, down) do
      w = w.parent
      if not w then break end
    end
  end
  if down and keyFocus then
    if keyFocus ~= lastMouseOver then mg.grabFocus() -- clear focus on clicking other widget
    end--else spawnKeysub(true) end -- 
  end
end
function _clickLeft() _mouseEvent(nil, 0, true) end
function _clickRight() _mouseEvent(nil, 2, true) end

function _keyEvent(key, down, accel)
  if keyFocus then keyFocus:onKeyEvent(key, down, accel) end
end
function _keyRepeatEvent(key, down, accel)
  if keyFocus and keyFocus:acceptsKeyRepeat() then keyFocus:onKeyEvent(key, down, accel, true) end
end
function _keyEscEvent()
  if keyFocus then
    local kf = keyFocus
    kf:releaseFocus()
    kf:onKeyEsc()
  end
end

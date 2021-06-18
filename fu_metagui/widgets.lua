local mg = metagui

local widgets = mg.widgetTypes
local mkwidget = mg.mkwidget
local debug = mg.debugFlags

do
end do -- layout ------------------------------------------------------------------------------------------------------------------------------------
  widgets.layout = mg.proto(mg.widgetBase, {
    -- widget attributes
    isBaseWidget = true,
    expandMode = {1, 0}, -- can expand to fill horizontally
    
    -- defaults
    mode = "manual",
    spacing = 2,
    align = 0.5,
  })
  
  -- layout modes:
  -- "manual" (the explicit default) is exactly what it says on the tim
  -- "horizontal" and "vertical" auto-arrange for each axis
  
  function widgets.layout:init(base, param)
    self.children = self.children or { } -- always have a children table
    
    -- parameters first
    self.mode = param.mode
    if self.mode == "h" then self.mode = "horizontal" end
    if self.mode == "v" then self.mode = "vertical" end
    self.spacing = param.spacing
    self.align = param.align
    
    if type(self.explicitSize) == "number" then
      --self.explicitSize = {self.explicitSize, self.explicitSize}
      if self.mode == "horizontal" then self.expandMode = {1, 0} end
      if self.mode == "vertical" then self.expandMode = {0, 1} end
    elseif type(self.explicitSize) == "table" then self.expandMode = {0, 0} end
    
    self.expandMode = param.expandMode or self.expandMode
    
    local scissoring = param.scissoring
    if scissoring == nil then scissoring = true end
    
    self.backingWidget = mkwidget(base, { type = "layout", layoutType = "basic", zlevel = param.zLevel, scissoring = scissoring })
    if debug.showLayoutBoxes then -- image to make it visible (random color)
      widget.addChild(self.backingWidget, { type = "image", file = string.format("/assetmissing.png?crop=0;0;1;1?multiply=0000?replace;0000=%06x4f", sb.makeRandomSource():randu32() % 0x1000000), scale = 1024 })
    end
    if type(param.children) == "table" then -- iterate through and add children
      for _, c in pairs(param.children) do
        if type(c) == "string" then
          if c == "spacer" then
            mg.createWidget({ type = "spacer" }, self)
          end
        elseif type(c) == "number" then mg.createWidget({ type = "spacer", size = math.floor(c) }, self)
        elseif c[1] then mg.createImplicitLayout(c, self) else
          mg.createWidget(c, self)
        end
      end
    end
  end
  
  function widgets.layout:preferredSize(width)
    width = width or (parent and parent.size[1]) or nil
    if type(self.explicitSize) == "table" then return self.explicitSize end
    local res = {0, 0}
    if self.mode == "horizontal" or self.mode == "vertical" then
      local axis = self.mode == "vertical" and 2 or 1
      local opp = 3 - axis
      
      res[axis] = -self.spacing --self.spacing * (#(self.children) - 1)
      
      for _, c in pairs(self.children) do if c.visible then
        local ps = c:preferredSize(width)
        if width and axis == 1 then width = width - ps[1] - self.spacing end
        res[opp] = math.max(res[opp], ps[opp])
        res[axis] = res[axis] + ps[axis] + self.spacing
      end end
      if type(self.explicitSize) == "number" then res[opp] = self.explicitSize end
    elseif self.mode == "stack" then
      if self.explicitSize then return self.explicitSize end
      for _, c in pairs(self.children) do if c.visible then
        local fc = c:preferredSize(width)
        res[1] = math.max(res[1], fc[1])
        res[2] = math.max(res[2], fc[2])
      end end
    elseif self.mode == "manual" then
      if self.explicitSize then return self.explicitSize end
      for _, c in pairs(self.children) do if c.visible then
        local fc = vec2.add(c.position, c:preferredSize(width))
        res[1] = math.max(res[1], fc[1])
        res[2] = math.max(res[2], fc[2])
      end end
    end
    return res
  end
  
  function widgets.layout:updateGeometry(noApply)
    -- autoarrange modes
    if self.mode == "horizontal" or self.mode == "vertical" then
      local axis = self.mode == "vertical" and 2 or 1
      local opp = 3 - axis
      
      -- find maximum expansion level
      -- if not zero, anything that matches it gets expanded to equal size after preferred sizes are fulfilled
      -- and while we're iterating through, determine total spacing size
      local exLv, sizeAcc = 1, -self.spacing
      for _, c in pairs(self.children) do if c.visible then
        sizeAcc = sizeAcc + self.spacing
        if c.expandMode[axis] > exLv then exLv = c.expandMode[axis] end
      end end
      local numEx = 0 -- count matching
      for _, c in pairs(self.children) do if c.visible and c.expandMode[axis] == exLv then numEx = numEx + 1 end end
      
      -- size pass 1
      for _, c in pairs(self.children) do
        if c.visible and c.expandMode[axis] < exLv then
          c.size = c:preferredSize(self.size[1])
          sizeAcc = sizeAcc + c.size[axis]
        end
      end
      -- and 2
      if numEx > 0 then
        local sz = (self.size[axis] - sizeAcc) / numEx
        local szf = math.floor(sz)
        local rm = 0
        for _, c in pairs(self.children) do
          if c.visible and c.expandMode[axis] == exLv then
            -- do a remainder-accumulator to keep things integer
            rm = rm + (sz - szf)
            local rmf = math.floor(rm)
            c.size = c:preferredSize(axis == 1 and szf+rmf or self.size[1])
            c.size[axis] = szf + rmf
            rm = rm - rmf
          end
        end
      end
      
      -- and position
      local posAcc = 0
      for _, c in pairs(self.children) do
        c.position = c.position or {0, 0}
        if c.visible then
          c.position[axis] = posAcc
          posAcc = posAcc + c.size[axis] + self.spacing
          -- resize or align on opposite axis
          if c.expandMode[opp] >= 1 then
            c.size[opp] = self.size[opp]
          else
            c.size[opp] = math.min(c.size[opp], self.size[opp]) -- force fit regardless
            c.position[opp] = math.floor(self.size[opp]*self.align - c.size[opp]*self.align)
          end
        end
      end
      
    elseif self.mode == "stack" then -- stacked on top of each other
      for _, c in pairs(self.children) do
        c.position = {0, 0}
        c.size = c:preferredSize(self.size[1])
        for a=1,2 do
          if c.expandMode[a] >= 1 then c.size[a] = self.size[a] end
        end
      end
    end
    
    -- propagate
    for _, c in pairs(self.children or { }) do c:updateGeometry(true) end
    -- finally, apply
    if not noApply then self:applyGeometry() end
  end
end do -- panel -------------------------------------------------------------------------------------------------------------------------------------
  widgets.panel = mg.proto(mg.widgetBase, {
    expandMode = {1, 2}, -- can expand to fill horizontally, wants to expand vertically
    
    style = "convex",
  })
  
  local padding = 2
  
  function widgets.panel:init(base, param)
    self.children = self.children or { }
    
    if type(self.explicitSize) == "number" then self.explicitSize = {self.explicitSize, 0} end
    
    self.style = param.style
    self.expandMode = param.expandMode
    
    self.backingWidget = mkwidget(base, { type = "canvas" })
    mg.createImplicitLayout(param.children, self, { mode = "vertical" })
  end
  
  function widgets.panel:preferredSize(width)
    if width then width = width - padding*2 end
    local res = vec2.add(self.children[1]:preferredSize(width), {padding*2, padding*2})
    if self.explicitSize then
      res[1] = self.explicitSize[1] or res[1]
      res[2] = self.explicitSize[2] or res[2]
    end
    return res
  end
  function widgets.panel:updateGeometry(noApply)
    local l = self.children[1]
    l.position = {padding, padding}
    l.size = vec2.sub(self.size, {padding*2, padding*2})
    
    l:updateGeometry(true)
    if not noApply then applyGeometry() end
  end
  function widgets.panel:draw()
    theme.drawPanel(self)
  end
end do -- scroll area -------------------------------------------------------------------------------------------------------------------------------
  widgets.scrollArea = mg.proto(mg.widgetBase, {
    isBaseWidget = true,
    expandMode = {1, 2}, -- can expand to fill horizontally, wants to expand vertically
    
    scrollDirections = {0, 1},
    scrollBars = true,
    thumbScrolling = true,
  })
  
  local scrollMode = { }
  mg.startEvent(function()
    coroutine.yield() -- queue
    scrollMode = mg.settings.scrollMode or {true, true}
    if not scrollMode[1] and not scrollMode[2] then scrollMode = {true, true} end -- force both if both disabled
  end)
  
  local sizeMod = {0, 0}
  local scrollFriction = 0.025
  local scrollVelocityThreshold = 0.25
  local wheelScrollAmount = 64
  local wheelScrollTicks = 6
  
  function widgets.scrollArea:init(base, param)
    self.children = self.children or { }
    
    if type(self.explicitSize) == "number" then self.expandMode = {1, 0}
    elseif type(self.explicitSize) == "table" then self.expandMode = {0, 0} end
    
    self.expandMode = param.expandMode or self.expandMode
    self.scrollDirections = param.scrollDirections
    self.scrollBars = param.scrollBars
    self.thumbScrolling = param.thumbScrolling
    
    self.velocity = {0, 0}
    
    self.subWidgets = { }
    self.subWidgets.back = mkwidget(base, { type = "canvas" })
    self.backingWidget = mkwidget(base, { type = "layout", layoutType = "basic" })
    self.subWidgets.front = mkwidget(base, { type = "canvas", mouseTransparent = true })
    
    mg.createImplicitLayout(param.children, self, { mode = "vertical", scissoring = false })
  end
  
  function widgets.scrollArea:addChild(...) return self.children[1]:addChild(...) end
  function widgets.scrollArea:clearChildren(...) return self.children[1]:clearChildren(...) end
  
  --local function roundVec(v) return {math.floor(0.5 + v[1]), math.floor(0.5 + v[2])} end
  
  local function evFling(self)
    while not self.deleted and vec2.mag(self.velocity) >= scrollVelocityThreshold do
      self:scrollBy(self.velocity)
      self.velocity = vec2.mul(self.velocity, 1.0 - scrollFriction)
      coroutine.yield()
    end
  end
  
  local function evWheel(self)
    if self._wheelControl then self._wheelControl.cancel = true end -- cancel old
    local control = { }
    self._wheelControl = control
    local abort = false
    local sp = self:scrollPosition()
    for i = 1, wheelScrollTicks do
      if self.deleted or control.cancel or not self.wheelTarget then abort = true break end -- abort
      self:scrollTo(vec2.lerp((i / wheelScrollTicks)^0.5, sp, self.wheelTarget), false, true)
      coroutine.yield()
    end
    if not abort then
      self.wheelTarget = nil
    end
  end
  
  local sdActive, sdVal
  local function scrollDirCheck()
    -- try the fast route first
    local r = mg.fastCheckShift()
    if r ~= nil then return r end
    
    -- else do the slow check once per continuous scrolling
    local aa = sdActive
    sdActive = 25
    if aa then return sdVal end
    
    mg.startEvent(function()
      while true do
        sdVal = mg.checkShift()
        for i = 1, 15000 do
          sdActive = sdActive -1
          if sdActive == 0 then
            sdActive = nil
            sdVal = nil
            return
          end
          coroutine.yield()
        end
      end
    end)
    return sdVal
  end
  
  -- only intercept if it can actually scroll
  function widgets.scrollArea:isMouseInteractable(init) 
    return init or 
    (self.scrollDirections[2] ~= 0 and self.children[1].size[2] > self.size[2]) or
    (self.scrollDirections[1] ~= 0 and self.children[1].size[1] > self.size[1])
  end
  function widgets.scrollArea:isWheelInteractable() return scrollMode[1] and self:isMouseInteractable() end
  function widgets.scrollArea:onMouseButtonEvent(btn, down)
    if down and not self:hasMouse() and scrollMode[2] then
      if self._wheelControl then self._wheelControl.cancel = true end -- cancel wheel scrolling
      self.velocity = {0, 0}
      self:captureMouse(btn)
      return true
    elseif not down and btn == self:mouseCaptureButton() then
      mg.startEvent(evFling, self)
      return self:releaseMouse()
    end
  end
  function widgets.scrollArea:onMouseWheelEvent(dir)
    if self:hasMouse() then return true end -- no wheel scrolling while dragging
    self.velocity = {0, 0} -- cancel fling
    local amt = dir * wheelScrollAmount
    local v
    if self.scrollDirections[2] ~= 0 then
      if self.scrollDirections[1] ~= 0 then
        local b = scrollDirCheck()
        if b == nil then return true end -- no scrolling until first value checked
        if b then v = {amt, 0} else v = {0, amt} end -- scroll direction
      else
        v = {0, amt}
      end
    else
      v = {amt, 0}
    end
    local sp = self:scrollPosition()
    if self.wheelTarget and vec2.dot(vec2.norm(v), vec2.norm(vec2.sub(self.wheelTarget, sp))) < 1.0 then
      self.wheelTarget = nil -- cancel and start anew if scrolling in a different direction
    end
    self.wheelTarget = vec2.add(v, self.wheelTarget or sp)
    mg.startEvent(evWheel, self)
    return true
  end
  function widgets.scrollArea:canPassMouseCapture() return self:isMouseInteractable() and scrollMode[2] end
  function widgets.scrollArea:onPassedMouseCapture(point) self.velocity = {0, 0} self:scrollBy(vec2.sub(mg.mousePosition, point)) end
  function widgets.scrollArea:onCaptureMouseMove(delta)
    if self.thumbScrolling and self:mouseCaptureButton() == 1 then -- middle click, "thumb mode"
      self.velocity = {0, 0}
      if vec2.mag(delta) == 0 then return nil end -- no scrolling without movement
      local l = self.children[1]
      local margin = 16
      local mpos, tpos = self:relativeMousePosition(), {0, 0}
      for i=1,2 do -- calculate relative position
        tpos[i] = util.clamp((mpos[i] - margin) / math.max(1, self.size[i] - margin*2), 0.0, 1.0) * (l.size[i] - self.size[i])
      end
      self:scrollTo(vec2.add(tpos, vec2.mul(self.size, 0.5)))
    else -- normal delta scrolling
      self.velocity = delta
      self:scrollBy(delta)
    end
  end
  function widgets.scrollArea:scrollBy(delta, suppressAnimation)
    delta = vec2.mul(delta, self.scrollDirections) -- limit to available directions
    local l = self.children[1]
    l.position = vec2.add(l.position, vec2.mul(delta, {1, -1}))
    l.position = rect.ll(rect.bound(rect.fromVec2(l.position, l.position), {math.max(0, l.size[1] - self.size[1]) * -1, math.max(0, l.size[2] - self.size[2]) * -1, 0, 0}))
    self:applyGeometry(true)
    self.children[1]:applyGeometry(true)
    if self.scrollBars and not suppressAnimation and vec2.mag(delta) > 0 and self:isMouseInteractable() then
      theme.onScroll(self) -- only if there's actually room to scroll and delta is nonzero
    end
  end
  function widgets.scrollArea:scrollTo(pos, suppressAnimation, raw)
    if not raw then pos = vec2.sub(pos, vec2.mul(self.size, 0.5)) end
    local l = self.children[1]
    l.position = vec2.mul(vec2.mul(pos, -1), self.scrollDirections)
    l.position = rect.ll(rect.bound(rect.fromVec2(l.position, l.position), {math.max(0, l.size[1] - self.size[1]) * -1, math.max(0, l.size[2] - self.size[2]) * -1, 0, 0}))
    self:applyGeometry(true)
    self.children[1]:applyGeometry(true)
    if self.scrollBars and not suppressAnimation and self:isMouseInteractable() then
      theme.onScroll(self) -- only if there's actually room to scroll
    end
  end
  function widgets.scrollArea:scrollPosition() return vec2.mul(self.children[1].position, -1) end
  
  function widgets.scrollArea:preferredSize(width) return vec2.add(self.children[1]:preferredSize(width + sizeMod[1]), sizeMod) end
  function widgets.scrollArea:updateGeometry(noApply)
    local l = self.children[1]
    l.size = vec2.sub(self.size, sizeMod)
    local ps = l:preferredSize(self.scrollDirections[1] == 0 and self.size[1])
    for i = 1, 2 do
      if self.scrollDirections[i] > 0 then
        l.size[i] = math.max(l.size[i], ps[i])
      end
    end
    --l.size[2] = ps[2]
    
    l:updateGeometry(true)
    -- snap scroll to bounds
    l.position = rect.ll(rect.bound(rect.fromVec2(l.position, l.position), {math.max(0, l.size[1] - self.size[1]) * -1, math.max(0, l.size[2] - self.size[2]) * -1, 0, 0}))
    if not noApply then applyGeometry() end
  end
  function widgets.scrollArea:applyGeometry(so)
    mg.widgetBase.applyGeometry(self, so) -- base first
    for _,sw in pairs(self.subWidgets) do -- sync position
      widget.setPosition(sw, widget.getPosition(self.backingWidget))
      widget.setSize(sw, widget.getSize(self.backingWidget))
    end
  end
end do -- spacer ------------------------------------------------------------------------------------------------------------------------------------
  widgets.spacer = mg.proto(mg.widgetBase, {
    expandMode = {2, 2} -- prefer to expand
  })
  function widgets.spacer:init(base, param)
    if self.explicitSize then self.expandMode = {0, 0} end -- fixed size
  end
  function widgets.spacer:preferredSize()
    local p = self.explicitSize or 0
    if type(p) == "table" then return p end
    return {p, p}
  end
end do -- canvas ------------------------------------------------------------------------------------------------------------------------------------
  widgets.canvas = mg.proto(mg.widgetBase, {
    expandMode = {1, 1}, -- can expand if no size specified
    
    mouseTransparent = false,
  })
  
  function widgets.canvas:init(base, param)
    self.mouseTransparent = param.mouseTransparent
    
    if self.explicitSize then expandMode = {0, 0} end -- fixed size
    self.backingWidget = mkwidget(base, { type = "canvas" })
  end
  
  function widgets.canvas:preferredSize() return self.explicitSize or {64, 64} end
  function widgets.canvas:isMouseInteractable() return not self.mouseTransparent end
end do -- button ------------------------------------------------------------------------------------------------------------------------------------
  widgets.button = mg.proto(mg.widgetBase, {
    expandMode = {1, 0}, -- will expand horizontally, but not vertically
  })
  
  function widgets.button:init(base, param)
    self.expandMode = param.expandMode
    if param.inline then self.expandMode = {0, 0} end
    if param.expand then self.expandMode = {2, 0} end
    
    self.caption = mg.formatText(param.caption)
    self.captionOffset = param.captionOffset or {0, 0}
    self.color = param.color
    
    self.state = "idle"
    self.backingWidget = mkwidget(base, { type = "canvas" })
    if type(self.explicitSize) == "number" then self.explicitSize = {self.explicitSize, 16} end
  end
  
  function widgets.button:minSize() return {16, 16} end
  function widgets.button:preferredSize() return self.explicitSize or {64, 16} end
  
  function widgets.button:draw() theme.drawButton(self) end
  
  function widgets.button:isMouseInteractable() return true end
  function widgets.button:onMouseEnter()
    self.state = "hover"
    self:queueRedraw()
    theme.onButtonHover(self)
  end
  function widgets.button:onMouseLeave() self.state = "idle" self:queueRedraw() end
  function widgets.button:onMouseButtonEvent(btn, down)
    if btn == 0 then -- left button
      if down then
        self.state = "press"
        self:captureMouse(btn)
        self:queueRedraw()
        theme.onButtonClick(self)
      elseif self.state == "press" then
        self.state = "hover"
        self:releaseMouse()
        self:queueRedraw()
        mg.startEvent(self.onClick, self)
      end
      return true
    end
  end
  function widgets.button:onCaptureMouseMove()
    local dist = vec2.sub(metagui.mousePosition, self:mouseCapturePoint())
  	if vec2.mag(dist) >= 5 then
  		local _ = self:passMouseCapture() or self:releaseMouse()
  	end
  end
  
  function widgets.button:onClick() end
  
  function widgets.button:setText(t)
    self.caption = mg.formatText(t)
    self:queueRedraw()
    if self.parent then self.parent:queueGeometryUpdate() end
  end
end do -- icon button -------------------------------------------------------------------------------------------------------------------------------
  widgets.iconButton = mg.proto(widgets.button, {
    expandMode = {0, 0}, -- fixed size
    
    image = "/assetmissing.png",
  })
  
  function widgets.iconButton:init(base, param)
    self.size = nil -- force recalculate
    self:setImage(param.image, param.hoverImage, param.pressImage)
    
    self.state = "idle"
    self.backingWidget = mkwidget(base, { type = "canvas" })
  end
  
  function widgets.iconButton:preferredSize() return self.explicitSize or self.imgSize end
  
  function widgets.iconButton:draw() theme.drawIconButton(self) end
  function widgets.iconButton:setImage(main, hover, press)
    if not hover and not press and main:sub(-1, -1) == ':' then
      self.image = main .. "idle"
      self.hoverImage = main .. "hover"
      self.pressImage = main .. "press"
    else
      self.image = mg.path(main)
      self.hoverImage = mg.path(hover)
      self.pressImage = mg.path(press)
    end
    
    self.imgSize = root.imageSize(self.image)
    self:queueGeometryUpdate()
    self:queueRedraw()
  end
end do -- checkbox ----------------------------------------------------------------------------------------------------------------------------------
  widgets.checkBox = mg.proto(widgets.button, {
    expandMode = {0, 0}, -- fixed size
    
    checked = false,
  })
  
  local broadcastLevel = 2
  local hRadioFind = { } -- empty table as private event handle
  
  function widgets.checkBox:init(base, param)
    self.state = "idle"
    self.backingWidget = mkwidget(base, { type = "canvas" })
    self.checked = param.checked
    self.radioGroup = param.radioGroup
    self.value = param.value
    
    self:subscribeEvent("radioButtonChecked", function(self, btn)
      if btn ~= self and btn.radioGroup == self.radioGroup then
        self.checked = false
        self:queueRedraw()
      end
    end)
    self:subscribeEvent(hRadioFind, function(self, group)
      if self.radioGroup == group and self.checked then return  self end
    end)
  end
  
  function widgets.checkBox:preferredSize() return {12, 12} end
  function widgets.checkBox:draw() theme.drawCheckBox(self) end
  
  function widgets.checkBox:onMouseEnter()
    self.state = "hover"
    self:queueRedraw()
    --theme.onButtonHover(self)
  end
  function widgets.checkBox:onMouseButtonEvent(btn, down)
    if btn == 0 then -- left button
      if down then
        self.state = "press"
        self:captureMouse(btn)
        self:queueRedraw()
        theme.onCheckBoxClick(self)
      elseif self.state == "press" then
        self.state = "hover"
        if self.radioGroup then
          if not self.checked then
            self.checked = true
            self:wideBroadcast(broadcastLevel, "radioButtonChecked", self)
          end
        else
          self.checked = not self.checked
        end
        self:releaseMouse()
        self:queueRedraw()
        mg.startEvent(self.onClick, self)
      end
      return true
    end
  end
  
  function widgets.checkBox:setChecked(b)
    if b and self.radioGroup and not self.checked then
      self.checked = true -- set before event
      self:wideBroadcast(broadcastLevel, "radioButtonChecked", self)
    end
    self.checked = b
    self:queueRedraw()
  end
  
  function widgets.checkBox:getGroupChecked()
    if not self.radioGroup then return nil end
    if self.checked then return self end
    return self:wideBroadcast(broadcastLevel, hRadioFind, self.radioGroup)
  end
  
  function widgets.checkBox:getGroupValue()
    local c = self:getGroupChecked()
    if c then return c.value end
    return nil -- explicit nil
  end
  --
end do -- label -------------------------------------------------------------------------------------------------------------------------------------
  widgets.label = mg.proto(mg.widgetBase, {
    expandMode = {1, 0}, -- will expand horizontally, but not vertically
    text = "",
  })
  
  function widgets.label:init(base, param)
    self.text = mg.formatText(param.text)
    self.color = param.color
    self.fontSize = param.fontSize
    self.align = param.align
    self.expandMode = param.expandMode
    
    if param.inline then self.expandMode = {0, 0} end
    if param.expand then self.expandMode = {2, 0} end
    
    self.backingWidget = mkwidget(base, { type = "canvas" })
  end
  
  function widgets.label:preferredSize(width)
    if self.explicitSize then return self.explicitSize end
    local s = mg.measureString(self.text, width, self.fontSize)
    -- extra pixel to fit cut-off descenders in multiline text
    if s[2] > math.ceil(self.fontSize or 8) then s[2] = s[2] + 1 end
    return s
  end
  
  function widgets.label:draw()
    local c = widget.bindCanvas(self.backingWidget) c:clear()
    local pos, ha = {0, self.size[2]}, "left"
    if self.align == "center" or self.align == "mid" then
      pos[1], ha = self.size[1] / 2, "mid"
    elseif self.align == "right" then
      pos[1], ha = self.size[1], "right"
    end
    local color = mg.getColor(self.color) or mg.getColor(theme.baseTextColor)
    if color then color = '#' .. color end
    c:drawText(self.text, { position = pos, horizontalAnchor = ha, verticalAnchor = "top", wrapWidth = self.size[1] + 1 }, self.fontSize or 8, color)
  end
  
  function widgets.label:setText(t)
    local old = self.text
    self.text = mg.formatText(t)
    if self.text ~= old then -- only do expensive parts if text actually changed
      self:queueRedraw()
      if self.parent then self.parent:queueGeometryUpdate() end
    end
  end
end do -- image -------------------------------------------------------------------------------------------------------------------------------------
  widgets.image = mg.proto(mg.widgetBase, {
    file = "/assetmissing.png", -- fallback file
    imgSize = {0, 0},
    scale = 1
  })
  
  function widgets.image:init(base, param)
    self.size = nil -- force recalculate
    self.noAutoCrop = param.noAutoCrop
    self.file = mg.path(param.file)
    if self.noAutoCrop then
      self.imgSize = root.imageSize(self.file)
    else
      local r = root.nonEmptyRegion(self.file) or {0, 0, 0, 0}
      self.imgSize = rect.size(r)
    end
    self.scale = param.scale
    if type(self.scale) == "number" then self.scale = {self.scale, self.scale} end
    
    self.backingWidget = mkwidget(base, { type = "canvas" })
  end
  function widgets.image:preferredSize()
    if self.explicitSize then return self.explicitSize end
    return {math.ceil(self.imgSize[1] * self.scale[1]), math.ceil(self.imgSize[2] * self.scale[2])}
  end
  function widgets.image:draw()
    local c = widget.bindCanvas(self.backingWidget)
    c:clear()
    if self.noAutoCrop then
      c:drawImageDrawable(self.file, vec2.mul(c:size(), 0.5), self.scale)
    else
      c:drawImageRect(self.file, root.nonEmptyRegion(self.file) or {0, 0, 0, 0}, rect.withCenter(vec2.mul(self.size, 0.5), vec2.mul(self.imgSize, self.scale)))
    end
  end
  function widgets.image:setFile(f, noAutoCrop)
    self.file = mg.path(f)
    if noAutoCrop ~= nil then self.noAutoCrop = noAutoCrop end
    if self.noAutoCrop then
      self.imgSize = root.imageSize(self.file)
    else
      local r = root.nonEmptyRegion(self.file) or {0, 0, 0, 0}
      self.imgSize = rect.size(r)
    end
    if parent then parent:queueGeometryUpdate() end
  end
  function widgets.image:setScale(v)
    self.scale = v
    if parent then parent:queueGeometryUpdate() end
  end
end do -- item slot ---------------------------------------------------------------------------------------------------------------------------------
  widgets.itemSlot = mg.proto(mg.widgetBase, {
    storedCount = 0
    --
  })
  
  local autoInteract = { } do -- modes
    function autoInteract.default(self, btn, container)
      if btn == 1 or btn > 2 then return nil end -- no default behavior
      
      -- don't attempt interaction if unsynced container
      if container and not mg.checkSync(true) then return nil end
      
      local itm, set
      if container then
        local cid = pane.sourceEntity()
        local off = (self.containerSlot or 1) - 1
        itm = world.containerItemAt(cid, off)
        set = function(item) world.containerSwapItemsNoCombine(cid, item, off) self:setItem(item) self:onItemModified() end
      else
        itm = self:item()
        set = function(item) self:setItem(item) self:onItemModified() end
      end
      
      local stm = player.swapSlotItem()
      if not itm and not stm then return nil end -- blank slot, blank cursor
      local canStack = mg.itemsCanStack(itm, stm)
      local maxStack = itm and mg.itemMaxStack(itm) or (stm and mg.itemMaxStack(stm))
      -- right clicking with an item that doesn't stack does nothing
      if btn == 2 and stm and not canStack then return nil end
      local shift = mg.checkShift() -- any case beyond could potentially be affected
      if btn == 0 then
        if shift then player.giveItem(itm) set() else
          if canStack and itm.count < maxStack then
            local c = math.min(stm.count, maxStack - itm.count)
            if c <= 0 then return nil end -- no change
            itm.count = itm.count + c
            stm.count = stm.count - c
            if stm.count <= 0 then stm = nil end
            player.setSwapSlotItem(stm) set(itm)
            return nil
          end
          if stm and not self:acceptsItem(stm) then return nil end
          player.setSwapSlotItem(itm) set(stm)
        end return nil
      elseif btn == 2 then -- if it gets here, same item is guaranteed
        if not stm then stm = { name = itm.name, count = 0, parameters = itm.parameters } end
        local c = math.min(shift and math.max(1, math.floor(itm.count/2)) or 1, maxStack - stm.count)
        if c <= 0 then return nil end -- no change
        stm.count = stm.count + c
        itm.count = itm.count - c
        if itm.count <= 0 then itm = nil end
        player.setSwapSlotItem(stm) set(itm)
        return nil
      end
    end
    function autoInteract.container(self, btn) return autoInteract.default(self, btn, true) end
    
    --
  end -- end modes
  
  function widgets.itemSlot:init(base, param)
    self.size = nil -- force recalculate
    self.hideRarity = param.hideRarity
    self.glyph = mg.path(param.glyph or param.colorGlyph)
    self.colorGlyph = not not param.colorGlyph -- some themes may want to render non-color glyphs as monochrome in their own colors
    self.color = param.color -- might as well let themes have at this
    self.autoInteract = param.autoInteract or param.auto
    self.containerSlot = param.containerSlot
    if self.containerSlot then self.autoInteract = "container" end
    --
    self.backingWidget = mkwidget(base, { type = "canvas" })
    self.subWidgets = {
      slot = mkwidget(base, { type = "itemslot", callback = "_clickLeft", rightClickCallback = "_clickRight", showRarity = false, showCount = false }),
      count = mkwidget(base, { type = "label", mouseTransparent = true, hAnchor = "right" })
    }
    if param.item then self:setItem(param.item) end
    if self.autoInteract == "container" then -- start polling loop
      mg.startEvent(function()
        local cid = pane.sourceEntity()
        coroutine.yield()
        while not self.deleted do
          self:setItem(world.containerItemAt(cid, (self.containerSlot or 1) - 1))
          coroutine.yield()
        end
      end)
    end
  end
  function widgets.itemSlot:preferredSize() return {18, 18} end
  function widgets.itemSlot:applyGeometry(so)
    mg.widgetBase.applyGeometry(self, so) -- base first
    local pos = widget.getPosition(self.backingWidget)
    widget.setPosition(self.subWidgets.slot, pos) -- sync position
    widget.setSize(self.subWidgets.slot, {18, 18})
    
    widget.setPosition(self.subWidgets.count, vec2.add(pos, {20, -3}))
  end
  function widgets.itemSlot:draw()
    widget.setText(self.subWidgets.count, self:prettyCount(self.storedCount))
    theme.drawItemSlot(self)
  end
  function widgets.itemSlot:prettyCount(num)
    num = num or self.storedCount
    if num <= 1 then return ""
    elseif num > 999999999 then return math.floor(num / 1000000000) .. "B"
    elseif num > 999999 then return math.floor(num / 1000000) .. "M"
    elseif num > 9999 then return math.floor(num / 1000) .. "K"
    end return "" .. num
  end
  
  function widgets.itemSlot:isMouseInteractable() return true end
  function widgets.itemSlot:onMouseEnter() self.hover = true self:queueRedraw() end
  function widgets.itemSlot:onMouseLeave() self.hover = false self:queueRedraw() end
  function widgets.itemSlot:onMouseButtonEvent(btn, down)
    if self.autoInteract then
      if down then self:captureMouse(btn)
      elseif btn == self:mouseCaptureButton() then
        self:releaseMouse()
        mg.startEvent(autoInteract[self.autoInteract] or autoInteract.default, self, btn)
      end
      return true
    end
  end
  widgets.itemSlot.onCaptureMouseMove = widgets.button.onCaptureMouseMove -- yoink
  
  function widgets.itemSlot:acceptsItem() return true end
  function widgets.itemSlot:onItemModified() end
  
  function widgets.itemSlot:item() return widget.itemSlotItem(self.subWidgets.slot) end
  function widgets.itemSlot:setItem(itm)
    local old = self:item()
    self.storedCount = itm and itm.count or 0
    widget.setItemSlotItem(self.subWidgets.slot, itm)
    self:queueRedraw()
    return old
  end
end do -- item grid ---------------------------------------------------------------------------------------------------------------------------------
  widgets.itemGrid = mg.proto(mg.widgetBase, {
    -- widget attributes
    isBaseWidget = true,
    
    -- defaults
    spacing = 2,
  })
  
  function widgets.itemGrid:init(base, param)
    self.children = self.children or { } -- always have a children table
    
    self.columns = param.columns
    self.spacing = param.spacing
    if type(self.spacing) == "number" then self.spacing = {self.spacing, self.spacing} end
    self.autoInteract = param.autoInteract or param.auto
    self.containerSlot = param.containerSlot
    if self.containerSlot then self.autoInteract = "container" end
    
    self.backingWidget = mkwidget(base, { type = "layout", layoutType = "basic", scissoring = false })
    
    local slots = param.slots or 1
    for i=1,slots do self:addSlot() end
  end
  
  function widgets.itemGrid:addSlot(item)
    local s = self:addChild {
      type = "itemSlot",
      autoInteract = self.autoInteract,
      item = item,
    }
    if not self.autoInteract then
      s.onMouseButtonEvent = function(...) return self.onSlotMouseEvent(...) end
      s.onCaptureMouseMove = function(...) return self.onCaptureMouseMove(...) end
    end
    self:queueGeometryUpdate() -- new slots need positioned
  end
  function widgets.itemGrid:removeSlot(index) if self.children[index] then self.children[index]:delete() end end
  function widgets.itemGrid:slot(index) return self.children[index] end
  function widgets.itemGrid:setNumSlots(num)
    local count = #self.children
    if count > num then
      for i=count, num+1, -1 do self.children[i]:delete() end
    elseif count < num then
      for i=count+1, num do self:addSlot() end
    end
  end
  
  function widgets.itemGrid:onSlotMouseEvent(btn, down) end
  
  function widgets.itemGrid:item(index) if not self:slot(index) then return nil end return self:slot(index):item() end
  function widgets.itemGrid:setItem(index, item) if not self:slot(index) then return nil end return self:slot(index):setItem(item) end
  
  function widgets.itemGrid:preferredSize(width)
    local dim = {0, 0}
    
    if self.columns then dim[1] = self.columns else
      width = width + self.spacing[1]
      local sw = 18 + self.spacing[1]
      dim[1] = math.modf(width / sw)
    end
    
    local w, p = math.modf(#(self.children) / dim[1])
    dim[2] = w + math.ceil(p)
    
    return {dim[1] * 18 + self.spacing[1] * (dim[1] - 1), dim[2] * 18 + self.spacing[2] * (dim[2] - 1)}
  end
  
  function widgets.itemGrid:updateGeometry()
    local container = self.autoInteract == "container"
    local slots = #(self.children)
    local cols = math.modf((self.size[1] + self.spacing[1]) / (18 + self.spacing[1]))
    for i, s in pairs(self.children) do
      s.index = i -- shove this in for script use
      if container then s.containerSlot = (self.containerSlot or 1) + i - 1 end
      local row = math.modf((i-1) / cols)
      local col = i - 1 - (row*cols)
      s.position = {(18 + self.spacing[1]) * col, (18 + self.spacing[2]) * row}
    end
    self:applyGeometry()
  end
end do -- list item ---------------------------------------------------------------------------------------------------------------------------------
  widgets.listItem = mg.proto(mg.widgetBase, {
    expandMode = {1, 0}, -- assumed to be vertical list
    
    padding = 2,
  })
  widgets.menuItem = widgets.listItem -- modified alias
  
  function widgets.listItem:init(base, param)
    self.children = self.children or { }
    self.isMenuItem = param.type == "menuItem"
    
    self.expandMode = param.expandMode
    self.padding = param.padding
    self.buttonLike = param.buttonLike
    self.noAutoSelect = param.noAutoSelect
    self.selectionGroup = param.selectionGroup
    
    widgets.listItem.widgetType = "listItem" -- force it here so nondeterministic iteration order doesn't screw us
    if self.isMenuItem then -- implicit settings
      self.widgetType = "menuItem" -- store this in the widget
      if self.buttonLike == nil then self.buttonLike = true end
      if self.noAutoSelect == nil then self.noAutoSelect = true end
    end
    
    self.backingWidget = mkwidget(base, { type = "canvas" })
    mg.createImplicitLayout(param.children, self, { mode = "horizontal" })
    
    self:subscribeEvent("listItemSelected", function(self, itm)
      if itm ~= self and itm.selectionGroup == self.selectionGroup then
        self:deselect()
      end
    end)
  end
  
  function widgets.listItem:addChild(...) return self.children[1]:addChild(...) end
  function widgets.listItem:clearChildren(...) return self.children[1]:clearChildren(...) end
  
  function widgets.listItem:preferredSize(width)
    if self.explicitSize then return self.explicitSize end
    if width then width = width - self.padding*2 end
    return vec2.add(self.children[1]:preferredSize(width), {self.padding*2, self.padding*2})
  end
  function widgets.listItem:updateGeometry(noApply)
    local l = self.children[1]
    l.position = {self.padding, self.padding}
    l.size = vec2.sub(self.size, {self.padding*2, self.padding*2})
    
    l:updateGeometry(true)
    if not noApply then applyGeometry() end
  end
  function widgets.listItem:draw() theme.drawListItem(self) end
  
  function widgets.listItem:isMouseInteractable() return true end
  function widgets.listItem:onMouseEnter() self.hover = true self:queueRedraw() end
  function widgets.listItem:onMouseLeave() self.hover = false self:queueRedraw() end
  function widgets.listItem:onMouseButtonEvent(btn, down)
    if down and not self:hasMouse() then
      self:captureMouse(btn)
      -- stop containing scroll area
      local p = self:findParent("scrollArea")
      if p then p.velocity = {0, 0} end
      theme.onListItemClick(self)
  	elseif not down then
  		if btn == self:mouseCaptureButton() then
  			self:releaseMouse()
        if not self.noAutoSelect then self:select() end
        mg.startEvent(self.onClick, self, btn)
      end
    end
    return true
  end
  
  widgets.listItem.onCaptureMouseMove = widgets.button.onCaptureMouseMove -- just yoink this
  
  function widgets.listItem:select()
    if self.selected then return nil end -- no need
    self.selected = true
    self:queueRedraw()
    self:broadcast("listItemSelected", self)
    mg.startEvent(self.onSelected, self)
  end
  function widgets.listItem:deselect()
    if not self.selected then return nil end
    self.selected = false
    self:queueRedraw()
  end
  function widgets.listItem:onSelected() end
  function widgets.listItem:onClick() end
end do -- text box ----------------------------------------------------------------------------------------------------------------------------------
  widgets.textBox = mg.proto(mg.widgetBase, {
    expandMode = {1, 0},
    
    text = "", textWidth = 0,
    caption = "",
    cursorPos = 0,
    scrollPos = 0,
    frameWidth = 4,
  })
  
  local ptLast = '^(.*%W+)%w%w-%W-$'
  local ptNext = '^%W-%w%w-(%W+.*)$'
  
  function widgets.textBox:init(base, param)
    self.caption = param.caption
    
    self.expandMode = param.expandMode
    if param.inline then self.expandMode = {0, 0} end
    if param.expand then self.expandMode = {2, 0} end
    
    self.backingWidget = mkwidget(base, { type = "canvas" })
    self.subWidgets = { content = mkwidget(base, { type = "canvas" }) }
  end
  function widgets.textBox:preferredSize() return {96, 14} end
  function widgets.textBox:draw()
    theme.drawTextBox(self)
    widget.setPosition(self.subWidgets.content, vec2.add(widget.getPosition(self.backingWidget), {self.frameWidth, 0}))
    widget.setSize(self.subWidgets.content, vec2.add(widget.getSize(self.backingWidget), {self.frameWidth*-2, 0}))
    local c = widget.bindCanvas(self.subWidgets.content) c:clear()
    local color = self.focused and "#ffffff" or "#bfbfbf"
    local vc = self.size[2]/2
    if self.focused then -- cursor
      local p = mg.measureString(self.text:sub(1, self.cursorPos))[1] - self.scrollPos
      c:drawRect({p, vc-4, p+0.5, vc+4}, '#' .. mg.getColor("accent"))
    elseif self.text == "" then
      c:drawText(self.caption, { position = {0, vc}, horizontalAnchor = "left", verticalAnchor = "mid" }, 8, "#7f7f7f")
    end
    c:drawText(self.text, { position = {-self.scrollPos, vc}, horizontalAnchor = "left", verticalAnchor = "mid" }, 8, color)
  end
  
  function widgets.textBox:isMouseInteractable() return true end
  function widgets.textBox:onMouseButtonEvent(btn, down)
    if btn == 0 and down then
      if not self.focused then
        self:grabFocus()
        self:moveCursor(self.text:len())
      else -- find cursor position from mouse
        local tp = self:relativeMousePosition()[1] + self.scrollPos - self.frameWidth
        local fcp, len = 0, self.text:len() 
        for i = 1, len do
          local m = mg.measureString(self.text:sub(1, i))[1]
          if m > tp then break end
          fcp = i
        end
        self:setCursorPosition(fcp)
      end
      return self:captureMouse(btn)
    elseif not down and btn == self:mouseCaptureButton() then
      return self:releaseMouse()
    end
  end
  function widgets.textBox:onCaptureMouseMove(delta)
    if delta[1] ~= 0 then
      self:setScrollPosition(self.scrollPos - delta[1])
    end
  end
  
  function widgets.textBox:focus()
    if not self.focused then
      self:grabFocus()
      self:moveCursor(self.text:len())
    end
  end
  function widgets.textBox:blur() self:releaseFocus() end
  
  function widgets.textBox:setText(t)
    local c = self.text
    self.text = type(t) == "string" and t or ""
    if self.text ~= c then
      self.textWidth = mg.measureString(self.text)[1]
      self:queueRedraw()
      mg.startEvent(self.onTextChanged, self)
    end
  end
  
  function widgets.textBox:setScrollPosition(p)
    self.scrollPos = math.max(0, math.min(p, self.textWidth - (self.size[1] - self.frameWidth * 2) + 1))
    self:queueRedraw()
  end
  function widgets.textBox:setCursorPosition(p)
    local c = self.cursorPos
    self.cursorPos = util.clamp(p, 0, self.text:len())
    if self.cursorPos ~= c then
      self:queueRedraw()
      local cw = self.size[1] - self.frameWidth * 2 -- content width
      local cl = cw/2 - 3 -- content limit
      local p = mg.measureString(self.text:sub(1, self.cursorPos))[1] - cw/2
      self:setScrollPosition(util.clamp(self.scrollPos, p-cl, p+cl))
    end
  end
  function widgets.textBox:moveCursor(o) self:setCursorPosition(self.cursorPos + o) end
  
  function widgets.textBox:onFocus() self.focused = true self:queueRedraw() end
  function widgets.textBox:onUnfocus() self.focused = false self:queueRedraw() end
  function widgets.textBox:onKeyEsc() mg.startEvent(self.onEscape, self) end
  function widgets.textBox:acceptsKeyRepeat() return true end
  function widgets.textBox:onKeyEvent(key, down, accel, rep)
    if down then
      if key == mg.keys.enter or key == mg.keys.kpEnter then
        self:releaseFocus()
        mg.startEvent(self.onEnter, self)
      elseif key == mg.keys.left then
        if accel.ctrl then
          local m = self.text:sub(1, self.cursorPos):match(ptLast)
          self:setCursorPosition(m and m:len() or 0)
        else
          self:moveCursor(-1)
        end
      elseif key == mg.keys.right then
        if accel.ctrl then
          local m = self.text:sub(self.cursorPos+1):match(ptNext)
          self:setCursorPosition(m and (self.text:len() - m:len()) or self.text:len())
        else
          self:moveCursor(1)
        end
      elseif key == mg.keys.home then self:setCursorPosition(0)
      elseif key == mg.keys["end"] then self:setCursorPosition(self.text:len())
      elseif key == mg.keys.del then
        if accel.alt then
          self:setText()
        elseif accel.ctrl then
          local m = self.text:sub(self.cursorPos+1):match(ptNext)
          self:setText(self.text:sub(1, self.cursorPos) .. (m or ""))
        else
          self:setText(self.text:sub(1, self.cursorPos) .. self.text:sub(self.cursorPos+2))
        end
      elseif key == mg.keys.backspace then
        if accel.alt then
          self:setText()
        elseif accel.ctrl then
          local m = self.text:sub(1, self.cursorPos):match(ptLast)
          self:setText(self.text:sub(1, m and m:len() or 0) .. self.text:sub(self.cursorPos+1))
          self:setCursorPosition(m and m:len() or 0)
        else
          self:setText(self.text:sub(1, self.cursorPos-1) .. self.text:sub(self.cursorPos+1))
          self:moveCursor(-1)
        end
      else -- try as printable key
        local char = mg.keyToChar(key, accel)
        if char then
          self:setText(self.text:sub(1, self.cursorPos) .. char .. self.text:sub(self.cursorPos+1))
          self:moveCursor(1)
        end
      end
      --mg.setTitle("key: " .. key)
    end
  end
  
  -- events out
  function widgets.textBox:onTextChanged() end
  function widgets.textBox:onEnter() end
  function widgets.textBox:onEscape() end
end do -- tab field ---------------------------------------------------------------------------------------------------------------------------------
  widgets.tabField = mg.proto(mg.widgetBase, {
    expandMode = {1, 2}, -- can expand to fill horizontally, wants to expand vertically
    layout = "horizontal",
    tabWidth = 80,
  })
  
  local linv = {
    horizontal = "vertical",
    vertical = "horizontal",
  }
  
  local tabHeight = 16
  
  function widgets.tabField:init(base, param)
    self.children = self.children or { }
    
    if type(self.explicitSize) == "number" then self.explicitSize = {self.explicitSize, 0} end
    
    self.layout = param.layout
    if not linv[self.layout] then self.layout = nil end
    self.tabWidth = param.tabWidth
    self.expandMode = param.expandMode
    self.noFocusFirstTab = param.noFocusFirstTab
    
    -- and build
    local layout = self.layout
    local inv = linv[layout]
    
    local base = mg.createImplicitLayout({ }, self, { mode = inv })
    local panel = base:addChild { type = "panel", style = "flat" or "concave" }
    local tabScroll = panel.children[1]:addChild { type = "scrollArea", children = { { mode = layout, align = 0, spacing = 1 } } }
    if layout == "horizontal" then
      panel.explicitSize = {0, tabHeight + 4}
      panel.expandMode = {2, 0}
      tabScroll.scrollDirections = {1, 0}
    else
      panel.explicitSize = {self.tabWidth + 4}
      panel.expandMode = {0, 2}
    end
    local surround = base:addChild { type = "layout", mode = "vertical", expandMode = {1, 1} }
    local stack = surround:addChild { type = "layout", mode = "stack", expandMode = {1, 1} }
    local bottomBar = mg.createImplicitLayout(param.bottomBar, surround, { })
    self.tabScroll = tabScroll
    self.surround = surround
    self.stack = stack
    self.bottomBar = bottomBar
    
    panel.tabStyle = layout -- set style var
    
    self.tabs = { }
    for id, p in ipairs(param.tabs or { }) do
      self:newTab(p)
    end
    --
  end
  
  function widgets.tabField:preferredSize(width)
    local res = self.children[1]:preferredSize(width)
    if self.explicitSize then res[1] = self.explicitSize[1] end
    return res
  end
  function widgets.tabField:updateGeometry(noApply)
    local l = self.children[1]
    l.size = vec2.mul(self.size, 1.0) -- quick copy
    
    l:updateGeometry(true)
    if not noApply then applyGeometry() end
  end
  
  local tabProto = { }
  local tabMt = { __index = tabProto }
  
  function tabProto:setTitle(txt, icon)
    self.titleWidget:setText(txt or tab.id)
    if icon ~= nil then
      self.iconWidget:setFile(icon or nil)
      self.iconWidget:setVisible(not not icon)
    end
  end
  function tabProto:setColor(c)
    self.tabWidget.color = c
    self.tabWidget:queueRedraw()
  end
  function tabProto:setVisible(b)
    self.tabWidget:setVisible(b)
  end
  function tabProto:select()
    self.tabWidget:select()
  end
  
  local function evContentsTabChanged(self, tab)
    self:setVisible(self.tab == tab)
  end
  local function evTabSelect(self)
    local tf = self.tab.parent
    local old = tf.currentTab
    tf.currentTab = self.tab
    tf:pushEvent("tabChanged", self.tab, old)
    mg.startEvent(tf.onTabChanged, tf, self.tab, old)
  end
  function widgets.tabField:newTab(param)
    local first = not self.tabScroll.children[1].children[1] -- check if first tab added
    
    local tab = setmetatable({ parent = self, id = param.id or sb.makeUuid() }, tabMt)
    self.tabs[tab.id] = tab
    
    -- set up tab widget itself
    tab.tabWidget = self.tabScroll.children[1]:addChild { type = "listItem", sizes = {0, tabHeight}, expandMode = self.layout == "vertical" and {1, 0} or {0, 0}, padding = 0, buttonLike = true, visible = param.visible }
    tab.tabWidget.children[1]:addChild { type = "spacer", size = {0, tabHeight} } -- manual padding
    tab.iconWidget = tab.tabWidget.children[1]:addChild { type = "image", size = {tabHeight, tabHeight}, visible = false }
    tab.titleWidget = tab.tabWidget.children[1]:addChild { type = "label", inline = true }
    tab.tabWidget.children[1]:addChild { type = "spacer", size = {0, tabHeight} } -- manual padding
    tab.tabWidget.tabStyle = self.layout -- set style var
    tab.tabWidget.color = param.color
    
    -- populate title and contents
    tab:setTitle(param.title, param.icon)
    tab.contents = mg.createImplicitLayout(param.contents, self.stack, { mode = "vertical", visible = false })
    
    -- hook up events
    tab.tabWidget.tab = tab
    tab.tabWidget.onSelected = evTabSelect
    tab.contents.tab = tab
    tab.contents:subscribeEvent("tabChanged", evContentsTabChanged)
    
    if first and not self.noFocusFirstTab then tab:select() end
    return tab
  end
  
  function widgets.tabField:onTabChanged() end
  
  
end

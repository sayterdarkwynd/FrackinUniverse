-- Frackin' Standard theme

local mg = metagui
local assets = theme.assets

assets.windowBorder = mg.ninePatch "windowBorder"
assets.windowBg = mg.asset "windowBg.png"
assets.buttonColored = mg.ninePatch "button"--Colored"

local color = { } do -- mini version of StardustLib's color.lua
  function color.toHex(rgb, hash)
    local h = hash and "#" or ""
    if type(rgb) == "string" then return string.format("%s%s", h, rgb:gsub("#","")) end
    return string.format(rgb[4] and "%s%02x%02x%02x%02x" or "%s%02x%02x%02x", h,
      math.floor(0.5 + rgb[1] * 255),
      math.floor(0.5 + rgb[2] * 255),
      math.floor(0.5 + rgb[3] * 255),
      math.floor(0.5 + (rgb[4] or 1.0) * 255)
    )
  end
  
  function color.toRgb(hex)
    if type(hex) == "table" then return hex end
    hex = hex:gsub("#", "") -- strip hash if present
    return {
      tonumber(hex:sub(1, 2), 16) / 255,
      tonumber(hex:sub(3, 4), 16) / 255,
      tonumber(hex:sub(5, 6), 16) / 255,
      (hex:len() == 8) and (tonumber(hex:sub(7, 8), 16) / 255)
    }
  end
  
  function color.replaceDirective(from, to, continue)
    local l = continue and { } or { "?replace" }
    local num = math.min(#from, #to)
    for i = 1, num do table.insert(l, string.format(";%s=%s", color.toHex(from[i]), color.toHex(to[i]))) end
    return table.concat(l)
  end
  
  -- code borrowed from https://github.com/Wavalab/rgb-hsl-rgb/blob/master/rgbhsl.lua; license unknown :(
  -- {
  local function hslToRgb(h, s, l)
    if s == 0 then return l, l, l end
    local function to(p, q, t)
        if t < 0 then t = t + 1 end
        if t > 1 then t = t - 1 end
        if t < .16667 then return p + (q - p) * 6 * t end
        if t < .5 then return q end
        if t < .66667 then return p + (q - p) * (.66667 - t) * 6 end
        return p
    end
    local q = l < .5 and l * (1 + s) or l + s - l * s
    local p = 2 * l - q
    return to(p, q, h + .33334), to(p, q, h), to(p, q, h - .33334)
  end
  
  local function rgbToHsl(r, g, b)
    local max, min = math.max(r, g, b), math.min(r, g, b)
    local t = max + min
    local h = t / 2
    if max == min then return 0, 0, h end
    local s, l = h, h
    local d = max - min
    s = l > .5 and d / (2 - t) or d / t
    if max == r then h = (g - b) / d % 6
    elseif max == g then h = (b - r) / d + 2
    elseif max == b then h = (r - g) / d + 4
    end
    return h * .16667, s, l
  end
  -- }
  
  function color.fromHsl(hsl)
    local c = { hslToRgb(table.unpack(hsl)) }
    c[4] = hsl[4] -- add alpha if present
    return c
  end
  
  function color.toHsl(c)
    c = color.toRgb(c)
    local hsl = { rgbToHsl(table.unpack(c)) }
    hsl[4] = c[4]
    return hsl
  end
end -- color lib

local paletteFor do

  local basePal = { "588adb", "123166", "0d1f40", "060f1f" }
  local framePal = {
    "ffe15c", "ffbd00", "c78b05", "875808", -- yellow bands
    "b3eeff", "7be1ff", "00c6ff", -- gems
  }
  
  if not theme.paletteShades then
    theme.paletteShades = { }
    local pal = theme.stockPalette or basePal
    local rs = color.toHsl(pal[1]) -- root shade
    for i = 1, 3 do
      local cs = color.toHsl(pal[i+1]) -- comparison shade
      theme.paletteShades[i] = { cs[2] / rs[2], cs[3] / rs[3] }
    end
  end
  local ps = theme.paletteShades
  
  local pals = { }--[theme.defaultAccentColor] = "" }
  local bgAlpha = 0.9
  paletteFor = function(col)
    col = mg.getColor(col)
    if pals[col] then return pals[col] end
    local h, s, l = table.unpack(color.toHsl(col))
    s = math.min(s, 0.64532019704433)
    local function c(v) return util.clamp(v, 0, 1) end
    local r
    if col == theme.defaultAccentColor and theme.stockPalette then
      local pm = util.mergeTable({ }, theme.stockPalette)
      for i=2,4 do pm[i] = string.format("%s%02x", pm[i], math.floor(0.5 + bgAlpha * 255)) end
      r = color.replaceDirective(basePal, pm)
    else
      r = color.replaceDirective(basePal, {
        col, -- highlight
        color.fromHsl { h, c(s * ps[1][1]), c(l * ps[1][2]), bgAlpha }, -- bg
        color.fromHsl { h, c(s * ps[2][1]), c(l * ps[2][2]), bgAlpha }, -- bg dark
        color.fromHsl { h, c(s * ps[3][1]), c(l * ps[3][2]), bgAlpha }, -- bg shadow
      })
    end
    
    local hd = (mg.cfg[theme.hueShiftProperty or false] or mg.cfg["frackin:hueShift"] or 0) / 360
    if hd ~= 0 then -- adjust frame colors
      hd = (hd+0.5 % 1) - 0.5
      -- tone down some of the harsher results
      local mp = math.min(math.abs(hd), 0.4)
      local sm = 1.0 - mp * 1.5
      local lm = 1.0 - math.min(mp, 0.2) * 1.0
      local frp = { }
      for i, pc in pairs(framePal) do
        local nc = color.toHsl(pc)
        nc[1] = nc[1] + hd -- hue shift
        nc[2] = nc[2] * sm -- sat mult
        nc[3] = nc[3] * lm -- lum mult
        frp[i] = color.fromHsl(nc)
      end
      r = r .. color.replaceDirective(framePal, frp, true)
    end
    --
    
    pals[col] = r
    return r
  end
end

if theme._export then
  theme._export.color = color
  theme._export.paletteFor = paletteFor
end

-- set up fixed directives for some stock functionality
theme.scrollBarDirectives = paletteFor "accent" .. "?multiply=ffffff7f"

local titleBar, icon, title, close, spacer
function theme.decorate()
  local style = mg.cfg.style
  widget.addChild(frame.backingWidget, { type = "canvas", position = {0, 0}, size = frame.size }, "canvas")
  
  if (style == "window") then
    titleBar = frame:addChild { type = "layout", position = {6, 2}, size = {frame.size[1] - 24 - 5, 23}, mode = "horizontal", align = 0.55 }
    icon = titleBar:addChild { type = "image" }
    spacer = titleBar:addChild { type = "spacer", size = 0 }
    spacer.expandMode = {0, 0}
    title = titleBar:addChild { type = "label", expand = true, align = "left" }
    close = frame:addChild{
      type = "iconButton", position = {frame.size[1] - 24, 8},
      image = "/interface/x.png", hoverImage = "/interface/xhover.png", pressImage = "/interface/xpress.png"
    }
    function close:onClick()
      pane.dismiss()
    end
  end
end

function theme.drawFrame()
  local style = mg.cfg.style
  c = widget.bindCanvas(frame.backingWidget .. ".canvas")
  c:clear() --assets.frame:drawToCanvas(c)
  
  local pal = paletteFor "accent"
  
  if (style == "window") then
    local bgClipWindow = rect.withSize({4, 4}, vec2.sub(c:size(), {4+6, 4+4}))
    c:drawTiledImage(assets.windowBg .. pal, {0, 0}, bgClipWindow)
    assets.windowBorder:drawToCanvas(c, "frame" .. pal)
    
    spacer.explicitSize = (not mg.cfg.icon) and -2 or 1
    icon.explicitSize = (not mg.cfg.icon) and {-1, 0} or nil
    icon:setFile(mg.cfg.icon)
    title:setText("^shadow;" .. mg.cfg.title:gsub('%^reset;', '^reset;^shadow;'))
  else assets.frame:drawToCanvas(c, "default" .. pal) end
end

function theme.drawPanel(w)
  if w.tabStyle and theme.useTabStyling then return theme.drawTabPanel(w) end
  local c = widget.bindCanvas(w.backingWidget)
  c:clear() assets.panel:drawToCanvas(c, (w.style or "convex") .. paletteFor "accent")
end

function theme.drawTabPanel(w)
  local c = widget.bindCanvas(w.backingWidget)
  c:clear() assets.tabPanel:drawToCanvas(c, w.tabStyle .. paletteFor "accent")
end

function theme.drawTab(w)
  local c = widget.bindCanvas(w.backingWidget) c:clear()
  local state
  if w.selected and not theme.tabsNoFocusFrame then state = "focus"
  elseif w.hover then state = "hover"
  else state = "idle" end
  state = w.tabStyle .. "." .. state .. paletteFor(w.color or "accent")
  
  assets.tab:drawToCanvas(c, state)
  --[[if w.selected then
    assets.tab:drawToCanvas(c, w.tabStyle .. ".accent?multiply=" .. mg.getColor(w.color or "accent"))
  end]]
end

function theme.drawButton(w)
  local c = widget.bindCanvas(w.backingWidget)
  c:clear() local pal = paletteFor(w.color or "accent")
  assets.button:drawToCanvas(c, (w.state or "idle") .. pal)
  if w.color == "accent" then
    assets.button:drawToCanvas(c, "accent" .. pal .. "?multiply=ffffff7f")
  end
  theme.drawButtonContents(w)
end

function theme.drawCheckBox(w)
  local c = widget.bindCanvas(w.backingWidget) c:clear()
  local state
  if w.state == "press" then state = ":toggle"
  else state = w.checked and ":checked" or ":idle" end
  state = state .. paletteFor("accent")
  
  local img = w.radioGroup and assets.radioButton or assets.checkBox
  c:drawImageDrawable(img .. state, vec2.mul(c:size(), 0.5), 1.0)
end

function theme.drawTextBox(w)
  local c = widget.bindCanvas(w.backingWidget)
  c:clear() assets.textBox:drawToCanvas(c, (w.focused and "focused" or "idle") .. paletteFor "accent")
end

function theme.drawItemSlot(w)
  local center = {9, 9}
  local c = widget.bindCanvas(w.backingWidget)
  c:clear() c:drawImage(assets.itemSlot .. ":" .. (w.hover and "hover" or "idle") .. paletteFor "accent", center, nil, nil, true)
  if w.glyph then
    if w.colorGlyph then
      c:drawImage(w.glyph, center, nil, nil, true)
    else
      c:drawImage(string.format("%s?multiply=%s?multiply=ffffff7f", w.glyph, mg.getColor "accent"), center, nil, nil, true)
    end
  end
  local ic = root.itemConfig(w:item())
  if ic and not w.hideRarity then
    local rarity = (ic.parameters.rarity or ic.config.rarity or "Common"):lower()
    c:drawImage(assets.itemRarity .. ":" .. rarity .. (w.hover and "?brightness=50" or ""), center, nil, nil, true)
  end
end

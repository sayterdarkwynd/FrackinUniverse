metagui = metagui or { }
local mg = metagui

local nps = { }

local npp = { }
local nppm = { __index = npp }

-- calculates all points involved in a ninepatch
local function npMatrix(r, m)
  local h = { r[1], r[1] + m[1], r[3] - m[3], r[3] }
  local v = { r[2], r[2] + m[2], r[4] - m[4], r[4] }
  local res = { { }, { }, { }, { } }
  for y=1,4 do
    for x=1,4 do
      res[y][x] = {h[x], v[y]}
    end
  end
  return res
end

-- calls the above, then arranges matrix into section rects
local function npRs(r, m)
  local mx = npMatrix(r, m)
  local res = { }
  for y=1,3 do
    for x=1,3 do
      local bl, tr = mx[y][x], mx[y+1][x+1]
      table.insert(res, { bl[1], bl[2], tr[1], tr[2]})
    end
  end
  return res
end

-- export
mg.npMatrix = npMatrix
mg.npRs = npRs

function npp:drawToCanvas(c, f, r)
  if not r then
    local s = c:size()
    r = {0, 0, s[1], s[2]}
  end
  f = f or "default"
  local sr = {0, 0, self.frameSize[1], self.frameSize[2]}
  local invm = {self.margins[1], self.margins[4], self.margins[3], self.margins[2]}
  local scm = invm
  if self.isHD then
    scm = { } for k,v in pairs(invm) do scm[k] = v*0.5 end
  end
  local img = string.format("%s:%s", self.image, f)
  
  local rc, sc = npRs(r, scm), npRs(sr, invm)
  for i=1,9 do c:drawImageRect(img, sc[i], rc[i]) end
end

function mg.ninePatch(path)
  -- rectify path input
  path = mg.asset((path:match('^(.*)%..-$') or path) .. ".png")
  path = path:match('^(.*)%..-$') or path
  if nps[path] then return nps[path] end
  local np = setmetatable({ }, nppm) nps[path] = np
  np.image = path .. ".png"
  local d = root.assetJson(path .. ".frames")
  np.margins = d.ninePatchMargins
  np.frameSize = d.frameGrid.size
  np.isHD = d.isHD
  return np
end

function mg.measureString(str, wrapWidth, size)
  pane.addWidget({ type = "label", value = str, wrapWidth = wrapWidth, fontSize = size }, "__measure")
  local s = widget.getSize("__measure")
  pane.removeWidget("__measure")
  return s
end

function mg.getColor(c)
  if c == "none" then return nil end
  if c == "accent" then
    if mg.cfg.accentColor == "accent" then return "7f7f7f" end
    return mg.getColor(mg.cfg.accentColor)
  end
  return c
end

function mg.formatText(str)
  if not str then return nil end
  local colorSub = {
    ["^accent;"] = string.format("^#%s;", mg.getColor("accent")),
  }
  str = string.gsub(str, "(%b^;)", colorSub)
  return str
end

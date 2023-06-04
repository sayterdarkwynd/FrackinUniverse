--

local mg = metagui

settings = { }
local modules = { }

local moduleProto = { }
local moduleMt = extend(moduleProto)
local pageProto = { }
local pageMt = extend(pageProto)

local loadedPages = { }

local ap = mg.cfg.assetPath
local function setAssetPath(p)
  mg.cfg.assetPath = p or ap
end

local scriptId, scriptPath
function settings.module(p)
  p = p or { }
  local m = setmetatable({ }, moduleMt)
  m.id = p.id or scriptId
  m.weight = p.weight
  m.assetPath = scriptPath
  
  m.pages = { }
  
  modules[m.id] = m
  return m
end

function moduleProto:page(p)
  local pg = setmetatable({ }, pageMt)
  pg.module = self
  pg.title = p.title
  pg.icon = p.icon
  pg.contents = p.contents
  
  table.insert(self.pages, pg)
  return pg
end

function pageProto:init() end
function pageProto:save() end

function tabField:onTabChanged(tab)
  local page = tab.page
  if not page.loaded then
    page.loaded = true
    setAssetPath(page.module.scriptPath)
    mg.widgetContext = page
    mg.createImplicitLayout(page.contents, tab.contents, { mode = "vertical", expandMode = {2, 2} })
    page:init()
    setAssetPath()
    
    table.insert(loadedPages, page)
  end
end

function apply:onClick()
  for _, p in pairs(loadedPages) do p:save() end
  player.setProperty("metagui:settings", metagui.settings)
  player.setProperty("metaGUISettings", nil) -- clear out old property
end
function cancel:onClick()
  pane.dismiss()
end

-- begin init

local registry = mg.registry
_ENV.registry = registry -- leave this here for modules

-- load in module scripts
for k, v in pairs(registry.settings) do
  scriptId = k
  scriptPath = util.pathDirectory(v)
  require(v)
end

local modSort = { }
for k, v in pairs(modules) do table.insert(modSort, v) end
table.sort(modSort, function(a, b) return a.weight < b.weight or (a.weight == b.weight and a.id < b.id) end)
for _, m in ipairs(modSort) do
  setAssetPath(m.scriptPath)
  for i, pg in ipairs(m.pages) do
    local tab = tabField:newTab{
      title = pg.title, icon = pg.icon,
    }
    tab.page = pg
  end
end
setAssetPath()

local firstTab = tabField.tabScroll.children[1].children[1]
if firstTab then firstTab:select() end

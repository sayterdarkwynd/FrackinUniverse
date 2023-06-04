-- Quick stub to load metaGUI's container proxy (safe to include)

function init()
  inputcfg = world.getObjectParameter(pane.containerEntityId(), "ui")
  inputdata = world.getObjectParameter(pane.containerEntityId(), "uiData")
  pane.sourceEntity = pane.containerEntityId
  require(root.assetJson("/panes.config").metaGUI.providerRoot .. "build.lua")
end

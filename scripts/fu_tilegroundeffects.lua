local oldtileMaterials = tileMaterials

tileMaterials = function()
  oldtileMaterials()
   
  local tileEffects_FU = root.assetJson("/tileEffects.config:FU_tiles")
  for k, v in pairs(tileEffects_FU) do
    tileEffects[k] = v
  end
end
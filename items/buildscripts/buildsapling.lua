require "/scripts/util.lua"

function build(directory, config, parameters, level, seed)
  if not parameters.stemName then
    -- a pine tree isn't PERFECTLY generic but it's close enough
    parameters.stemName = "pineytree"
    parameters.foliageName = parameters.foliageName or "pinefoliage"
  end

  config.inventoryIcon = jarray()

  table.insert(config.inventoryIcon, {
      image = string.format("%s?hueshift=%s", util.absolutePath(root.treeStemDirectory(parameters.stemName), "saplingicon.png"), parameters.stemHueShift or 0)
    })

  if parameters.foliageName then
    table.insert(config.inventoryIcon, {
        image = string.format("%s?hueshift=%s", util.absolutePath(root.treeFoliageDirectory(parameters.foliageName), "saplingicon.png"), parameters.foliageHueShift or 0)
      })
  end
  
  -- begin added code 
  if not parameters.foliageName then
     parameters.foliageName = "pinefoliage"
  end
  
  indice = parameters.stemName.."_"..parameters.foliageName
  saplings = {}
  saplings['cactus_bigflowers'] = "Cactus Big Flowers"
  saplings['cactus_cactusflowers'] = "Cactus Flowers"
  saplings['cactus_nothing'] = "Cactus"
  saplings['colourfulstem_colourfulpalm'] = "Colourful Palm"
  saplings['applewood_apple'] = "Apple Tree"
  saplings['bananatreestem_bananatreeleaf'] = "Banana Tree"
  saplings['bamboostem_bamboofoliage'] = "Bamboo Tree"
  saplings['alienbubble_alienbigleaf'] = "Alien Big Bubble"
  saplings['alienstriped_alienbigleaf'] = "Alien Big Stripped"
  saplings['alienweird_alienbigleaf'] = "Alien Big Weird"
  saplings['alienbubble_aliencircle'] = "Alien Circ. Bubble"
  saplings['alienstriped_aliencircle'] = "Alien Circ. Stripped"
  saplings['alienweird_aliencircle'] = "Alien Circ. Weird"
  saplings['peachwood_peach'] = "Peach Tree"
  saplings['pearwood_pear'] = "Pear Tree"
  saplings['energyorbstem_energyorbfoliage'] = "Energy Orb Tree"
  saplings['doomwood_doomy1'] = "Doom Wood Tree"
  saplings['burnttreestem_burntleaves'] = "Burnt Leaves Tree"
  saplings['burnttreestem_burntmoss'] = "Burnt Moss Tree"
  saplings['coconutwood_coconut'] = "Coconut Tree"
  saplings['crystalline2_crystallinenofoliage2'] = "Crystal Tree"
  saplings['crystalline3_crystallinenofoliagefull'] = "Crystal Full Tree"
  saplings['cherrybloomwood_cherrygreen'] = "Cherry Tree"
  saplings['cherrywood_cherrybloom'] = "Cherry Bloom Tree"
  saplings['baobab_baobab'] = "Baobab Tree"
  saplings['pearlwood_pearlfoliage'] = "Pearl Fruit Tree"
  saplings['redwood_redwood1'] = "Redwood Tree"
  saplings['prototree_protoleaves'] = "Proto Tree"
  saplings['nyanistem_nyanifoliage'] = "Nyani Fruit Tree"
  saplings['tearnutstem_tearnutfoliage'] = "Tearnut Tree"
  saplings['coconut_cocopalm'] = "Coconut Palm Tree"
  saplings['deadtree1_deadleaves'] = "Deadleaves Tree"
  saplings['deadtree1_deadmoss'] = "Deadmoss Tree"
  saplings['slobby_pinefoliage'] = "Slobby Pine Tree"
  saplings['pineytree_pinefoliage'] = "Pine Tree"
  saplings['twirl_lushleaves'] = "Twirl Lush Tree"
  saplings['blank_lushleaves'] = "Blank Lush Tree"
  saplings['desertpalm_lushleaves'] = "Desert Lush Tree"
  saplings['palmlike_junglepalm'] = "Jungle Palm Tree"
  saplings['beach_palmleaves'] = "Beach Palm Tree"
  saplings['rainbowwood_rainbowleaves'] = "Rainbow Tree"
  saplings['rainbowfleshy_rainbowleaves'] = "Rainbow Flesh Tree"
  saplings['rainbowpine_rainbowleaves'] = "Rainbow Pine Tree"
  saplings['rustypipes_rustypipes'] = "Rusty Pipe Tree"
  saplings['orangestem_orangeleaf'] = "Orange Tree"
  saplings['rainbowslobby_rainbowleaves'] = "Rainbow Slobby Tree"
  saplings['rainbowgrumpy_rainbowleaves'] = "Rainbow Grumpy Tree"
  saplings['weeping_weepingleaves'] = "Weeping Leaf Tree"
  saplings['weeping_weeping'] = "Weeping Tree"
  saplings['eyestem_eyefoliage'] = "Eye Pile Tree"
  saplings['bleake_flatte'] = "Bleake Flatte Tree"
  saplings['rust_rustflower'] = "Rust Tree"
  saplings['fleshy_hanging'] = "Fleshy Hang Tree"
  saplings['fleshy_leafy'] = "Fleshy Leaf Tree"
  saplings['fleshy_frumpy'] = "Fleshy Frump Tree"
  saplings['cocoa_rose'] = "Cocoa Rose Tree"
  saplings['something_rose'] = "Some. Rose Tree"
  saplings['birch_cloudy'] = "Cloudy Birch Tree"
  saplings['wood_cloudy'] = "Cloudy Tree"
  saplings['desertpalm_roseleaves'] = "Desert Palm Tree"
  saplings['alienpalm_roseleaves'] = "Alien Palm Tree"
  saplings['plain_lushleaves'] = "Plain Lush Tree"
  saplings['grumpy_orangeflower'] = "Grump Orange Tree"
  saplings['grumpy_lushgreen'] = "Grump Lush Tree"
  saplings['palm_roseleaves'] = "Palm Rose Tree"
  saplings['giantflower_redflower'] = "Giant Flower Tree"
  saplings['spikey_greenleaves'] = "Spikey Green Tree"
  saplings['spikey_hanging'] = "Spikey Hang Tree"
  saplings['spikey_scraggy'] = "Spikey Scrag Tree"
  saplings['slimey_lushgreen'] = "Slimey Lush Tree"
  saplings['slimey_bubbles'] = "Slimey Bubble Tree"
  saplings['slimey_redleaves'] = "Slimey Red Tree"
  saplings['pine_hanging'] = "Pine Hang Tree"
  saplings['woody_jungleleaf'] = "Jungle Tree"
  saplings['pineytree_snowpine'] = "Snowy Pine Tree"
  saplings['birch_scraggy'] = "Scrag Birch Tree"
  saplings['snowslimey_snowscraggy'] = "Snow Slime Tree"
  saplings['snowfleshy_snowscraggy'] = "Snow Flesh Tree"
  saplings['snowmetal_snowscraggy'] = "Snow Metal Tree"
  saplings['snowsomething_snowredleaves'] = "Snow Red Tree"
  saplings['twisted_scraggy'] = "Twist Scrag Tree"
  saplings['edelwood_edelwoodleaves'] = "Edelwood Tree"
  saplings['edelwood_edelwoodleaves2'] = "Edelwood Dark Tree"
  saplings['chromatree_chromafoliage'] = "Pinky Chroma Tree"
  saplings['chromatree_chromafoliage2'] = "Cloudy Chroma Tree"
  saplings['chromatree_chromafoliage3'] = "Lush Chroma Tree"
  saplings['chromatree_chromafoliage4'] = "Green Chroma Tree"
  saplings['geode_geodefoliage'] = "Geode Tree"
  saplings['birch_frumpy'] = "Frumpy Birch Tree"
  saplings['mushroomstalkfu2_mushroomredtopfu2'] = "Red Shroom"
  saplings['mushroomstalk_mushroomyellowtop'] = "White Shroom"
  saplings['mushroomstalk_mushroomredtop'] = "Orange Shroom"
  saplings['beach_palmy'] = "Palmy Beach Tree"
  saplings['roottree_hanging'] = "Hang Root Tree"
  saplings['wood_lotus'] = "Lotus Tree"
  saplings['wood_lushgreen'] = "Lush Tree"
  saplings['savannahbleak_thorns'] = "Bleak Thorns Tree"
  saplings['bleak_squarish'] = "Bleak Square Tree"
  saplings['gloomy_squarish'] = "Gloom Square Tree"
  saplings['cocoa_bubbles'] = "Cocoa Bubble Tree"
  saplings['cocoa_frumpy'] = "Cocoa Frump Tree"
  saplings['gloomy_flat'] = "Gloom Flat Tree"
  saplings['gloomy_burly'] = "Gloom Burly Tree"
  saplings['bloodkelp_bloodkelpy'] = "Blood Kelp"
  saplings['aetherkelp_bloodkelpy'] = "Large Aether Kelp"
  saplings['aetherkelp2_bloodkelpy'] = "Aether Kelp"
  saplings['stripey_willowy'] = "Stripe Willow Tree"

  if saplings[indice] then
      parameters.shortdescription = saplings[indice].." Sapling"
      parameters.description = "A "..saplings[indice].." Sapling.\n^green;Foliage^reset;: "..parameters.foliageName.." (Hue:"..math.floor(math.abs(parameters.foliageHueShift or 0))..")\n^orange;Stem^reset;: "..parameters.stemName.." (Hue:"..math.floor(math.abs(parameters.stemHueShift or 0))..")" 
  else
      parameters.shortdescription = "Unknown"
      parameters.description = "A Unknown Sapling.\n^green;Foliage^reset;: "..parameters.foliageName.." (Hue:"..math.floor(math.abs(parameters.foliageHueShift or 0))..")\n^orange;Stem^reset;: "..parameters.stemName.." (Hue:"..math.floor(math.abs(parameters.stemHueShift or 0))..")" 
  end

  -- end added code
  
  return config, parameters
end

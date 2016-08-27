local recipes = {
{inputs = { mushroomseed=1 }, outputs = { gene_regen=1 }, time = 5.5},
{inputs = { kirifruitseed=1 }, outputs = { gene_energy=1 }, time = 5.5},
{inputs = { nakatiseed=1 }, outputs = { gene_defense=1 }, time = 5.5},
{inputs = { piruseed=1 }, outputs = { gene_agility=1 }, time = 5.5},
{inputs = { avaliplant1=1 }, outputs = { gene_energy=1 }, time = 5.5},
{inputs = { avaliplant2=1 }, outputs = { gene_defense=1 }, time = 5.5},
{inputs = { avaliplant3=1 }, outputs = { gene_agility=1 }, time = 5.5},
{inputs = { wildkirifruitseed=1 }, outputs = { gene_energy=1 }, time = 5.5},
{inputs = { wildnakatiseed=1 }, outputs = { gene_defense=1 }, time = 5.5},
{inputs = { wildpiruseed=1 }, outputs = { gene_agility=1 }, time = 5.5},
{inputs = { reedseed=1 }, outputs = { gene_assimilate=1 }, time = 5.5},
{inputs = { wildreedseed=1 }, outputs = { gene_assimilate=1 }, time = 5.5},
{inputs = { cottonseed=1 }, outputs = { gene_energy=1 }, time = 5.5},
{inputs = { wildcottonseed=1 }, outputs = { gene_energy=1 }, time = 5.5},
{inputs = { shroomblockglow=50 }, outputs = { gene_bioluminescent=1 }, time = 5.5},
{inputs = { cocoaseed=1 }, outputs = { gene_energy=1 }, time = 5.5},
{inputs = { wildcocoaseed=1 }, outputs = { gene_energy=1 }, time = 5.5},
{inputs = { biospore=4 }, outputs = { gene_bioluminescent=1 }, time = 5.5},
{inputs = { hopsseed=1 }, outputs = { gene_stimulant=1 }, time = 5.5},
{inputs = { cinnamonseed=1 }, outputs = { gene_stimulant=1 }, time = 5.5},
{inputs = { automatoseed=1 }, outputs = { gene_harden=1 }, time = 5.5},
{inputs = { avesmingoseed=1 }, outputs = { gene_chloroplast=1 }, time = 5.5},
{inputs = { bananaseed=1 }, outputs = { gene_resist=1 }, time = 5.5},
{inputs = { beakseedseed=1 }, outputs = { gene_avian=1 }, time = 5.5},
{inputs = { boltbulbseed=1 }, outputs = { gene_reactive=1 }, time = 5.5},
{inputs = { bonebooseed=1 }, outputs = { gene_skeletal=1 }, time = 5.5},
{inputs = { brackentreeseed=1 }, outputs = { gene_reproductive=1 }, time = 5.5},
{inputs = { carrotseed=1 }, outputs = { gene_resist=1 }, time = 5.5},
{inputs = { chiliseed=1 }, outputs = { gene_pyro=1 }, time = 5.5},
{inputs = { coffeeseed=1 }, outputs = { gene_energy=1 }, time = 5.5},
{inputs = { coralcreepseed=1 }, outputs = { gene_aquahomeo=1 }, time = 5.5},
{inputs = { cornseed=1 }, outputs = { gene_harden=1 }, time = 5.5},
{inputs = { crystalplantseed=1 }, outputs = { gene_stealth=1 }, time = 5.5},
{inputs = { currentcornseed=1 }, outputs = { gene_mimetic=1 }, time = 5.5},
{inputs = { diodiaseed=1 }, outputs = { gene_assimilate=1 }, time = 5.5},
{inputs = { dirturchinseed=1 }, outputs = { gene_muscle=1 }, time = 5.5},
{inputs = { eggshootseed=1 }, outputs = { gene_avian=1 }, time = 5.5},
{inputs = { feathercrownseed=1 }, outputs = { gene_stimulant=1 }, time = 5.5},
{inputs = { flowerblue=1 }, outputs = { gene_nervebundle=1 }, time = 5.5},
{inputs = { flowerblack=1 }, outputs = { gene_muscle=1 }, time = 5.5},
{inputs = { flowerbrown=1 }, outputs = { gene_energy=1 }, time = 5.5},
{inputs = { flowergreen=1 }, outputs = { gene_skeletal=1 }, time = 5.5},
{inputs = { flowergrey=1 }, outputs = { gene_reproductive=1 }, time = 5.5},
{inputs = { flowerorange=1 }, outputs = { gene_avian=1 }, time = 5.5},
{inputs = { flowerorchid=1 }, outputs = { gene_resist=1 }, time = 5.5},
{inputs = { flowerorchid2=1 }, outputs = { gene_resist=1 }, time = 5.5},
{inputs = { flowerorchid3=1 }, outputs = { gene_resist=1 }, time = 5.5},
{inputs = { flowerpink=1 }, outputs = { gene_aquahomeo=1 }, time = 5.5},
{inputs = { flowerpurple=1 }, outputs = { gene_assimilate=1 }, time = 5.5},
{inputs = { flowerwhite=1 }, outputs = { gene_mimetic=1 }, time = 5.5},
{inputs = { flowerred=1 }, outputs = { gene_regen=1 }, time = 5.5},
{inputs = { floweryellow=1 }, outputs = { gene_reproductive=1 }, time = 5.5},
{inputs = { flowerspring=1 }, outputs = { gene_reproductive=1 }, time = 5.5},
{inputs = { grapesseed=1 }, outputs = { gene_resist=1 }, time = 5.5},
{inputs = { kiwiseed=1 }, outputs = { gene_harden=1 }, time = 5.5},
{inputs = { neonmelonseed=1 }, outputs = { gene_assimilate=1 }, time = 5.5},
{inputs = { oculemonseed=1 }, outputs = { gene_ocular=1 }, time = 5.5},
{inputs = { pearlpeaseed=1 }, outputs = { gene_adaptivecell=1 }, time = 5.5},
{inputs = { pineappleseed=1 }, outputs = { gene_harden=1 }, time = 5.5},
{inputs = { potatoseed=1 }, outputs = { gene_resist=1 }, time = 5.5},
{inputs = { pussplumseed=1 }, outputs = { gene_muscle=1 }, time = 5.5},
{inputs = { reefpodseed=1 }, outputs = { gene_aquacelerity=1 }, time = 5.5},
{inputs = { riceseed=1 }, outputs = { gene_defense=1 }, time = 5.5},
{inputs = { sapling=1 }, outputs = { gene_harden=1 }, time = 5.5},
{inputs = { sugarcaneseed=1 }, outputs = { gene_stimulant=1 }, time = 5.5},
{inputs = { tomatoseed=1 }, outputs = { gene_nervebundle=1 }, time = 5.5},
{inputs = { toxictopseed=1 }, outputs = { gene_poisonous=1 }, time = 5.5},
{inputs = { wartweedseed=1 }, outputs = { gene_corrosive=1 }, time = 5.5},
{inputs = { wheatseed=1 }, outputs = { gene_chloroplast=1 }, time = 5.5},
{inputs = { dragonsbeardseed=1 }, outputs = { gene_pyro=1 }, time = 5.5},
{inputs = { minkocoapodseed=1 }, outputs = { gene_mammal=1 }, time = 5.5},
{inputs = { itaseed=1 }, outputs = { gene_chloroplast=1 }, time = 5.5},
{inputs = { nissseed=1 }, outputs = { gene_immunity=1 }, time = 5.5},
{inputs = { energiflowerseed=1 }, outputs = { gene_energy=1 }, time = 5.5},
{inputs = { lactariusindigoseed=1 }, outputs = { gene_reproductive=1 }, time = 5.5},
{inputs = { greenleafseed=1 }, outputs = { gene_chloroplast=1 }, time = 5.5},
{inputs = { guamseed=1 }, outputs = { gene_immunity=1 }, time = 5.5},
{inputs = { miraclegrassseed=1 }, outputs = { gene_regen=1 }, time = 5.5},
{inputs = { algaeseed=1 }, outputs = { gene_reproductive=1 }, time = 5.5},
{inputs = { bloodrootseed=1 }, outputs = { gene_regen=1 }, time = 5.5},
{inputs = { jillyrootseed=1 }, outputs = { gene_chloroplast=1 }, time = 5.5},
{inputs = { thornitoxseed=1 }, outputs = { gene_corrosive=1 }, time = 5.5},
{inputs = { wubstemseed=1 }, outputs = { gene_adaptivecell=1 }, time = 5.5},
{inputs = { darklightflower=1 }, outputs = { gene_immunity=1 }, time = 5.5},
{inputs = { goldenseaspongeplant=1 }, outputs = { gene_fish=1 }, time = 5},
{inputs = { fuspongeweedseed=1 }, outputs = { gene_fish=1 }, time = 5},
{inputs = { fusnowberryseed=1 }, outputs = { gene_cryo=1 }, time = 5},
{inputs = { garpberryseed=1 }, outputs = { gene_resist=1 }, time = 4.4},
{inputs = { varanberryseed=1 }, outputs = { gene_regen=1 }, time = 5.5},
{inputs = { cellpodsplant=1 }, outputs = { gene_insectoid=5 }, time = 5},
{inputs = { kamaranpodsplant=1 }, outputs = { gene_mimetic=4 }, time = 5},
{inputs = { tinselbush=1 }, outputs = { gene_reactive=1 }, time = 5.5},
{inputs = { poetree=1 }, outputs = { gene_assimilate=1 }, time = 5.5},
{inputs = { whitespine=1 }, outputs = { gene_immunity=1 }, time = 5.5},
{inputs = { isn_meatplant=1 }, outputs = { gene_void=1 }, time = 5.5},
{inputs = { mintseed=1 }, outputs = { gene_agility=1 }, time = 5.5},
{inputs = { onionseed=1 }, outputs = { gene_agility=1 }, time = 5.5},
{inputs = { yellowfootseed=1 }, outputs = { gene_energy=1 }, time = 5.5},
{inputs = { caprioleplantseed=1 }, outputs = { gene_muscle=1 }, time = 5.5},
{inputs = { petrifiedrootseed=1 }, outputs = { gene_void=1 }, time = 5.5},
{inputs = { littlegoodberryseed=1 }, outputs = { gene_regen=1 }, time = 5.5},
{inputs = { vanusflowerseed=1 }, outputs = { gene_defense=1 }, time = 5.5},
{inputs = { slimeplantseed=1 }, outputs = { gene_resist=1 }, time = 5.5},
{inputs = { stranglevineseed=1 }, outputs = { gene_reactive=1 }, time = 5.5},
{inputs = { ghostmushroomseed=1 }, outputs = { gene_stealth=1 }, time = 5.5},
{inputs = { goldshroomseed=1 }, outputs = { gene_harden=1 }, time = 5.5},
{inputs = { beeflowerseed=1 }, outputs = { gene_reproductive=1, gene_regen=1 }, time = 5.5 },
{inputs = { beetlesproutseed=1 }, outputs = { gene_harden=2, gene_insectoid=2 }, time = 5.5},
{inputs = { biscornseed=1 }, outputs = { gene_nervebundle=1 }, time = 5.5},
{inputs = { blizzberryseed=1 }, outputs = { gene_cryo=1 }, time = 5.5},
{inputs = { bluemelonseed=1 }, outputs = { gene_energy=1 }, time = 5.5},
{inputs = { blexplantseed=1 }, outputs = { gene_energy=1 }, time = 5.5},
{inputs = { aquapodseed=1 }, outputs = { gene_aquahomeo=1, gene_aquacelerity=1 }, time = 5.5},
{inputs = { bambooseed=1 }, outputs = { gene_reproductive=1 }, time = 1 },
{inputs = { blisterbushplantseed=1 }, outputs = { gene_bioluminescent=1 }, time = 5.5},
{inputs = { corvexseed=1 }, outputs = { gene_corrosive=1 }, time = 5.5},
{inputs = { deathblossomseed=1 }, outputs = { gene_poisonous=2 }, time = 5.5},
{inputs = { diodiahybridseed=1 }, outputs = { gene_mimetic=1 }, time = 5.5},
{inputs = { erithianalgaeseed=1 }, outputs = { gene_insectoid=1 }, time = 5.5},
{inputs = { floralytplantseed=1 }, outputs = { gene_regen=4 }, time = 5.5},
{inputs = { fubioshroomblue=1 }, outputs = { biospore=3 }, time = 5.5},
{inputs = { fubioshroomgreen=1 }, outputs = { biospore=3 }, time = 5.5},
{inputs = { fubioshroompurple=1 }, outputs = { biospore=3 }, time = 5.5},
{inputs = { fubioshroomred=1 }, outputs = { biospore=3 }, time = 5.5},
{inputs = { fubioshroomyellow=1 }, outputs = { biospore=3 }, time = 5.5},
{inputs = { fayshroomseed=1 }, outputs = { gene_stealth=1 }, time = 5.5},
{inputs = { ginsengseed=1 }, outputs = { gene_regen=1 }, time = 5.5},
{inputs = { goldenrootseed=1 }, outputs = { gene_mimetic=1 }, time = 5.5},
{inputs = { gazelemonseed=1 }, outputs = { gene_ocular=1 }, time = 5.5},
{inputs = { glarestalkseed=1 }, outputs = { gene_ocular=2 }, time = 5.5},
{inputs = { genesiberryseed=1 }, outputs = { gene_assimilate=3 }, time = 5.5},
{inputs = { goldenglowseed=1 }, outputs = { gene_bioluminescent=2 }, time = 5.5},
{inputs = { haleflowerseed=1 }, outputs = { gene_energy=4 }, time = 5.5},
{inputs = { hellfireplantseed=1 }, outputs = { gene_pyro=3 }, time = 5.5},
{inputs = { ighantseed=1 }, outputs = { gene_stimulant=1 }, time = 5.5},
{inputs = { ignuschiliseed=1 }, outputs = { gene_pyro=1, gene_reactive=1 }, time = 5.5},
{inputs = { ignuschili2seed=1 }, outputs = { gene_pyro=2, gene_reactive=2 }, time = 5.5},
{inputs = { lasherplantseed=1 }, outputs = { gene_rage=1 }, time = 5.5},
{inputs = { leafshellseed=1 }, outputs = { gene_defense=1 }, time = 5.5},
{inputs = { littlerascalseed=1 }, outputs = { gene_defense=2 }, time = 5.5},
{inputs = { melodistarseed=1 }, outputs = { gene_energy=2 }, time = 5.5},
{inputs = { mireurchinseed=1 }, outputs = { gene_agility=1 }, time = 5.5},
{inputs = { mutaviskseed=1 }, outputs = { gene_agility=1 }, time = 5.5},
{inputs = { naileryseed=1 }, outputs = { gene_reactive=1 }, time = 5.5},
{inputs = { neuropodseed=1 }, outputs = { gene_mimetic=2 }, time = 5.5},
{inputs = { oonfortaseed=1 }, outputs = { gene_bioluminescent=1 }, time = 5.5},
{inputs = { pasakavineseed=1 }, outputs = { gene_insectoid=1 }, time = 5.5},
{inputs = { pekkitseed=1 }, outputs = { gene_cryo=1 }, time = 5.5},
{inputs = { pinkloomseed=1 }, outputs = { gene_rage=1 }, time = 5.5},
{inputs = { porphisplantseed=1 }, outputs = { gene_muscle=1 }, time = 5.5},
{inputs = { rockrootseed=1 }, outputs = { gene_harden=4 }, time = 5.5},
{inputs = { shinyacornseed=1 }, outputs = { gene_defense=1 }, time = 5.5},
{inputs = { shockshroomseed=1 }, outputs = { gene_electric=2 }, time = 5.5},
{inputs = { silverleafseed=1 }, outputs = { gene_energy=1 }, time = 5.5},
{inputs = { springvaultseed=1 }, outputs = { gene_muscle=2 }, time = 5.5},
{inputs = { teratomatoseed=1 }, outputs = { gene_regen=3 }, time = 5.5},
{inputs = { talonseedseed=1 }, outputs = { gene_resist=1 }, time = 5.5},
{inputs = { tetherhookseed=1 }, outputs = { gene_void=2 }, time = 5.5},
{inputs = { tyvokkseed=1 }, outputs = { gene_immunity=1 }, time = 5.5},
{inputs = { vextongueseed=1 }, outputs = { gene_energy=1 }, time = 5.5},
{inputs = { voritseed=1 }, outputs = { gene_aquacelerity=2 }, time = 5.5},
{inputs = { vashtaplantseed=1 }, outputs = { gene_insectoid=1 }, time = 5.5},
{inputs = { wretchelseed=1 }, outputs = { gene_void=3 }, time = 5.5},
{inputs = { xaxseed=1 }, outputs = { gene_avian=3 }, time = 5.5},
{inputs = { zathiseed=1 }, outputs = { gene_avian=2 }, time = 5.5},
{inputs = { aenemaflower=1 }, outputs = { gene_energy=2 }, time = 5.5},
{inputs = { arkaentree=1 }, outputs = { gene_harden=2 }, time = 5.5},
{inputs = { batterystem=1 }, outputs = { gene_electric=2 }, time = 5.5},
{inputs = { bellamorte=1 }, outputs = { gene_poisonous=2 }, time = 5.5},
{inputs = { bladetree=1 }, outputs = { gene_reactive=2 }, time = 5.5},
{inputs = { crystallite=1 }, outputs = { gene_mimetic=2 }, time = 5.5},
{inputs = { fletchweed=1 }, outputs = { gene_chloroplast=2 }, time = 5.5},
{inputs = { garikleaf=1 }, outputs = { gene_regen=2 }, time = 5.5},
{inputs = { herrodbush=1 }, outputs = { gene_agility=2 }, time = 5.5},
{inputs = { kramil=1 }, outputs = { gene_immunity=2 }, time = 5.5},
{inputs = { quellstem=1 }, outputs = { gene_resist=2 }, time = 5.5},
{inputs = { victorleaf=1 }, outputs = { gene_muscle=2 }, time = 5.5},
{inputs = { tentacleplant=1 }, outputs = { gene_mimetic=2 }, time = 5.5},
{inputs = { fuavikancactusseed=1 }, outputs = { gene_defense=1 }, time = 5.5},
{inputs = { fuavikanspiceplantseed=1 }, outputs = { gene_mimetic=1 }, time = 5.5},
{inputs = { wildfuavikancactusseed=1 }, outputs = { gene_defense=1 }, time = 5.5},
{inputs = { wildfuavikanspiceplantseed=1 }, outputs = { gene_mimetic=1 }, time = 5.5},
{inputs = { wildcinnamonseed=1 }, outputs = { gene_stimulant=1 }, time = 5.5},
{inputs = { wildautomatoseed=1 }, outputs = { gene_harden=1 }, time = 5.5},
{inputs = { wildavesmingoseed=1 }, outputs = { gene_chloroplast=1 }, time = 5.5},
{inputs = { wildbananaseed=1 }, outputs = { gene_resist=1 }, time = 5.5},
{inputs = { wildbeakseedseed=1 }, outputs = { gene_avian=1 }, time = 5.5},
{inputs = { wildboltbulbseed=1 }, outputs = { gene_reactive=1 }, time = 5.5},
{inputs = { wildbonebooseed=1 }, outputs = { gene_skeletal=1 }, time = 5.5},
{inputs = { wildbrackentreeseed=1 }, outputs = { gene_reproductive=1 }, time = 5.5},
{inputs = { wildcarrotseed=1 }, outputs = { gene_resist=1 }, time = 5.5},
{inputs = { wildchiliseed=1 }, outputs = { gene_pyro=1 }, time = 5.5},
{inputs = { wildcoffeeseed=1 }, outputs = { gene_energy=1 }, time = 5.5},
{inputs = { wildcoralcreepseed=1 }, outputs = { gene_aquahomeo=1 }, time = 5.5},
{inputs = { wildcornseed=1 }, outputs = { gene_harden=1 }, time = 5.5},
{inputs = { wildcrystalplantseed=1 }, outputs = { gene_stealth=1 }, time = 5.5},
{inputs = { wildcurrentcornseed=1 }, outputs = { gene_mimetic=1 }, time = 5.5},
{inputs = { wilddiodiaseed=1 }, outputs = { gene_assimilate=1 }, time = 5.5},
{inputs = { wilddirturchinseed=1 }, outputs = { gene_muscle=1 }, time = 5.5},
{inputs = { wildeggshootseed=1 }, outputs = { gene_avian=1 }, time = 5.5},
{inputs = { wildfeathercrownseed=1 }, outputs = { gene_stimulant=1 }, time = 5.5},
{inputs = { wildflowerblue=1 }, outputs = { gene_nervebundle=1 }, time = 5.5},
{inputs = { wildflowerred=1 }, outputs = { gene_stimulant=1 }, time = 5.5},
{inputs = { wildfloweryellow=1 }, outputs = { gene_reproductive=1 }, time = 5.5},
{inputs = { wildflowerspring=1 }, outputs = { gene_reproductive=1 }, time = 5.5},
{inputs = { wildgrapesseed=1 }, outputs = { gene_resist=1 }, time = 5.5},
{inputs = { wildhopsseed=1 }, outputs = { gene_reactive=1 }, time = 5.5},
{inputs = { wildkiwiseed=1 }, outputs = { gene_harden=1 }, time = 5.5},
{inputs = { wildneonmelonseed=1 }, outputs = { gene_assimilate=1 }, time = 5.5},
{inputs = { wildoculemonseed=1 }, outputs = { gene_ocular=1 }, time = 5.5},
{inputs = { wildpearlpeaseed=1 }, outputs = { gene_adaptivecell=1 }, time = 5.5},
{inputs = { wildpineappleseed=1 }, outputs = { gene_harden=1 }, time = 5.5},
{inputs = { wildpotatoseed=1 }, outputs = { gene_resist=1 }, time = 5.5},
{inputs = { wildpussplumseed=1 }, outputs = { gene_muscle=1 }, time = 5.5},
{inputs = { wildreefpodseed=1 }, outputs = { gene_aquacelerity=1 }, time = 5.5},
{inputs = { wildriceseed=1 }, outputs = { gene_defense=1 }, time = 5.5},
{inputs = { wildsapling=1 }, outputs = { gene_harden=1 }, time = 5.5},
{inputs = { wildsugarcaneseed=1 }, outputs = { gene_stimulant=1 }, time = 5.5},
{inputs = { wildtomatoseed=1 }, outputs = { gene_nervebundle=1 }, time = 5.5},
{inputs = { wildtoxictopseed=1 }, outputs = { gene_poisonous=1 }, time = 5.5},
{inputs = { wildwartweedseed=1 }, outputs = { gene_corrosive=1 }, time = 5.5},
{inputs = { wildwheatseed=1 }, outputs = { gene_chloroplast=1 }, time = 5.5},
{inputs = { wilddragonsbeardseed=1 }, outputs = { gene_pyro=1 }, time = 5.5},
{inputs = { wildminkocoapodseed=1 }, outputs = { gene_mammal=1 }, time = 5.5},
{inputs = { wilditaseed=1 }, outputs = { gene_chloroplast=1 }, time = 5.5},
{inputs = { wildnissseed=1 }, outputs = { gene_immunity=1 }, time = 5.5},
{inputs = { wildenergiflowerseed=1 }, outputs = { gene_energy=1 }, time = 5.5},
{inputs = { wildlactariusindigoseed=1 }, outputs = { gene_reproductive=1 }, time = 5.5},
{inputs = { wildgreenleafseed=1 }, outputs = { gene_chloroplast=1 }, time = 5.5},
{inputs = { wildguamseed=1 }, outputs = { gene_immunity=1 }, time = 5.5},
{inputs = { wildmiraclegrassseed=1 }, outputs = { gene_regen=1 }, time = 5.5},
{inputs = { wildalgaeseed=1 }, outputs = { gene_reproductive=1 }, time = 5.5},
{inputs = { wildbloodrootseed=1 }, outputs = { gene_regen=1 }, time = 5.5},
{inputs = { wildjillyrootseed=1 }, outputs = { gene_chloroplast=1 }, time = 5.5},
{inputs = { wildthornitoxseed=1 }, outputs = { gene_corrosive=1 }, time = 5.5},
{inputs = { wildwubstemseed=1 }, outputs = { gene_adaptivecell=1 }, time = 5.5},
{inputs = { wilddarklightflower=1 }, outputs = { gene_immunity=1 }, time = 5.5},
{inputs = { wildgoldenseaspongeplant=1 }, outputs = { gene_fish=1 }, time = 5},
{inputs = { wildfuspongeweedseed=1 }, outputs = { gene_fish=1 }, time = 5},
{inputs = { wildfusnowberryseed=1 }, outputs = { gene_cryo=1 }, time = 5},
{inputs = { wildvaranberryseed=1 }, outputs = { gene_regen=1 }, time = 5.5},
{inputs = { wildcellpodsplant=1 }, outputs = { gene_insectoid=5 }, time = 5},
{inputs = { wildkamaranpodsplant=1 }, outputs = { gene_mimetic=4 }, time = 5},
{inputs = { wildtinselbush=1 }, outputs = { gene_reactive=1 }, time = 5.5},
{inputs = { wildpoetree=1 }, outputs = { gene_assimilate=1 }, time = 5.5},
{inputs = { wildwhitespine=1 }, outputs = { gene_immunity=1 }, time = 5.5},
{inputs = { wildisn_meatplant=1 }, outputs = { gene_void=1 }, time = 5.5},
{inputs = { wildmintseed=1 }, outputs = { gene_agility=1 }, time = 5.5},
{inputs = { wildonionseed=1 }, outputs = { gene_agility=1 }, time = 5.5},
{inputs = { wildyellowfootseed=1 }, outputs = { gene_energy=1 }, time = 5.5},
{inputs = { wildcaprioleplantseed=1 }, outputs = { gene_muscle=1 }, time = 5.5},
{inputs = { wildpetrifiedrootseed=1 }, outputs = { gene_void=1 }, time = 5.5},
{inputs = { wildlittlegoodberryseed=1 }, outputs = { gene_regen=1 }, time = 5.5},
{inputs = { wildvanusflowerseed=1 }, outputs = { gene_defense=1 }, time = 5.5},
{inputs = { wildslimeplantseed=1 }, outputs = { gene_resist=1 }, time = 5.5},
{inputs = { wildstranglevineseed=1 }, outputs = { gene_reactive=1 }, time = 5.5},
{inputs = { wildghostmushroomseed=1 }, outputs = { gene_stealth=1 }, time = 5.5},
{inputs = { wildgoldshroomseed=1 }, outputs = { gene_harden=1 }, time = 5.5},
{inputs = { wildbeeflowerseed=1 }, outputs = { gene_reproductive=1, gene_regen=1 }, time = 5.5 },
{inputs = { wildbeetlesproutseed=1 }, outputs = { gene_harden=2, gene_insectoid=2 }, time = 5.5},
{inputs = { wildbiscornseed=1 }, outputs = { gene_nervebundle=1 }, time = 5.5},
{inputs = { wildblizzberryseed=1 }, outputs = { gene_cryo=1 }, time = 5.5},
{inputs = { wildbluemelonseed=1 }, outputs = { gene_energy=1 }, time = 5.5},
{inputs = { wildblexplantseed=1 }, outputs = { gene_energy=1 }, time = 5.5},
{inputs = { wildaquapodseed=1 }, outputs = { gene_aquahomeo=1, gene_aquacelerity=1 }, time = 5.5},
{inputs = { wildbambooseed=1 }, outputs = { gene_reproductive=1 }, time = 1 },
{inputs = { wildblisterbushplantseed=1 }, outputs = { gene_bioluminescent=1 }, time = 5.5},
{inputs = { wildcorvexseed=1 }, outputs = { gene_corrosive=1 }, time = 5.5},
{inputs = { wilddeathblossomseed=1 }, outputs = { gene_poisonous=2 }, time = 5.5},
{inputs = { wilddiodiahybridseed=1 }, outputs = { gene_mimetic=1 }, time = 5.5},
{inputs = { wilderithianalgaeseed=1 }, outputs = { gene_insectoid=1 }, time = 5.5},
{inputs = { wildfloralytplantseed=1 }, outputs = { gene_regen=4 }, time = 5.5},
{inputs = { wildfubioshroomblue=1 }, outputs = { biospore=3 }, time = 5.5},
{inputs = { wildfubioshroomgreen=1 }, outputs = { biospore=3 }, time = 5.5},
{inputs = { wildfubioshroompurple=1 }, outputs = { biospore=3 }, time = 5.5},
{inputs = { wildfubioshroomred=1 }, outputs = { biospore=3 }, time = 5.5},
{inputs = { wildfubioshroomyellow=1 }, outputs = { biospore=3 }, time = 5.5},
{inputs = { wildfayshroomseed=1 }, outputs = { gene_stealth=1 }, time = 5.5},
{inputs = { wildginsengseed=1 }, outputs = { gene_regen=1 }, time = 5.5},
{inputs = { wildgoldenrootseed=1 }, outputs = { gene_mimetic=1 }, time = 5.5},
{inputs = { wildgazelemonseed=1 }, outputs = { gene_ocular=1 }, time = 5.5},
{inputs = { wildglarestalkseed=1 }, outputs = { gene_ocular=2 }, time = 5.5},
{inputs = { wildgenesiberryseed=1 }, outputs = { gene_assimilate=3 }, time = 5.5},
{inputs = { wildgoldenglowseed=1 }, outputs = { gene_bioluminescent=2 }, time = 5.5},
{inputs = { wildhaleflowerseed=1 }, outputs = { gene_energy=4 }, time = 5.5},
{inputs = { wildhellfireplantseed=1 }, outputs = { gene_pyro=3 }, time = 5.5},
{inputs = { wildighantseed=1 }, outputs = { gene_stimulant=1 }, time = 5.5},
{inputs = { wildignuschiliseed=1 }, outputs = { gene_pyro=2 }, time = 5.5},
{inputs = { wildignuschili2seed=1 }, outputs = { gene_pyro=3 }, time = 5.5},
{inputs = { wildlasherplantseed=1 }, outputs = { gene_rage=1 }, time = 5.5},
{inputs = { wildleafshellseed=1 }, outputs = { gene_defense=1 }, time = 5.5},
{inputs = { wildlittlerascalseed=1 }, outputs = { gene_defense=2 }, time = 5.5},
{inputs = { wildmelodistarseed=1 }, outputs = { gene_energy=2 }, time = 5.5},
{inputs = { wildmireurchinseed=1 }, outputs = { gene_agility=1 }, time = 5.5},
{inputs = { wildmutaviskseed=1 }, outputs = { gene_agility=1 }, time = 5.5},
{inputs = { wildnaileryseed=1 }, outputs = { gene_reactive=1 }, time = 5.5},
{inputs = { wildneuropodseed=1 }, outputs = { gene_mimetic=2 }, time = 5.5},
{inputs = { wildoonfortaseed=1 }, outputs = { gene_bioluminescent=1 }, time = 5.5},
{inputs = { wildpasakavineseed=1 }, outputs = { gene_insectoid=1 }, time = 5.5},
{inputs = { wildpekkitseed=1 }, outputs = { gene_cryo=1 }, time = 5.5},
{inputs = { wildpinkloomseed=1 }, outputs = { gene_rage=1 }, time = 5.5},
{inputs = { wildporphisplantseed=1 }, outputs = { gene_muscle=1 }, time = 5.5},
{inputs = { wildrockrootseed=1 }, outputs = { gene_harden=4 }, time = 5.5},
{inputs = { wildshinyacornseed=1 }, outputs = { gene_defense=1 }, time = 5.5},
{inputs = { wildshockshroomseed=1 }, outputs = { gene_electric=2 }, time = 5.5},
{inputs = { wildsilverleafseed=1 }, outputs = { gene_energy=1 }, time = 5.5},
{inputs = { wildspringvaultseed=1 }, outputs = { gene_muscle=2 }, time = 5.5},
{inputs = { wildteratomatoseed=1 }, outputs = { gene_regen=3 }, time = 5.5},
{inputs = { wildtalonseedseed=1 }, outputs = { gene_resist=1 }, time = 5.5},
{inputs = { wildtetherhookseed=1 }, outputs = { gene_void=2 }, time = 5.5},
{inputs = { wildtyvokkseed=1 }, outputs = { gene_immunity=1 }, time = 5.5},
{inputs = { wildvextongueseed=1 }, outputs = { gene_energy=1 }, time = 5.5},
{inputs = { wildvoritseed=1 }, outputs = { gene_aquacelerity=2 }, time = 5.5},
{inputs = { wildvashtaplantseed=1 }, outputs = { gene_insectoid=1 }, time = 5.5},
{inputs = { wildwretchelseed=1 }, outputs = { gene_void=3 }, time = 5.5},
{inputs = { wildxaxseed=1 }, outputs = { gene_avian=3 }, time = 5.5},
{inputs = { wildzathiseed=1 }, outputs = { gene_avian=2 }, time = 5.5},
{inputs = { wildaenemaflower=1 }, outputs = { gene_energy=2 }, time = 5.5},
{inputs = { wildarkaentree=1 }, outputs = { gene_harden=2 }, time = 5.5},
{inputs = { wildbatterystem=1 }, outputs = { gene_electric=2 }, time = 5.5},
{inputs = { wildbellamorte=1 }, outputs = { gene_poisonous=2 }, time = 5.5},
{inputs = { wildbladetree=1 }, outputs = { gene_reactive=2 }, time = 5.5},
{inputs = { wildcrystallite=1 }, outputs = { gene_mimetic=2 }, time = 5.5},
{inputs = { wildfletchweed=1 }, outputs = { gene_chloroplast=2 }, time = 5.5},
{inputs = { wildgarikleaf=1 }, outputs = { gene_regen=2 }, time = 5.5},
{inputs = { wildherrodbush=1 }, outputs = { gene_agility=2 }, time = 5.5},
{inputs = { wildkramil=1 }, outputs = { gene_immunity=2 }, time = 5.5},
{inputs = { wildquellstem=1 }, outputs = { gene_resist=2 }, time = 5.5},
{inputs = { wildvictorleaf=1 }, outputs = { gene_muscle=2 }, time = 5.5},
{inputs = { wildtentacleplant=1 }, outputs = { gene_mimetic=2 }, time = 5.5},

--produce
{inputs = { glowfibre=25 }, outputs = { gene_bioluminescent=1 }, time = 5.5},
{inputs = { plantfibre=25 }, outputs = { gene_reproductive=1 }, time = 5.5},
{inputs = { alienfruit=25 }, outputs = { gene_stimulant=1 }, time = 5.5},
{inputs = { automato=25 }, outputs = { gene_harden=1 }, time = 5.5},
{inputs = { avesmingo=25 }, outputs = { gene_chloroplast=1 }, time = 5.5},
{inputs = { banana=25 }, outputs = { gene_resist=1 }, time = 5.5},
{inputs = { boneboo=25 }, outputs = { gene_skeletal=1 }, time = 5.5},
{inputs = { cacti=25 }, outputs = { gene_defense=1 }, time = 5.5},
{inputs = { chili=25 }, outputs = { gene_pyro=1 }, time = 5.5},
{inputs = { carrot=25 }, outputs = { gene_resist=1 }, time = 5.5},
{inputs = { coffeebeans=25 }, outputs = { gene_energy=1 }, time = 5.5},
{inputs = { coralcreep=25 }, outputs = { gene_aquahomeo=1 }, time = 5.5},
{inputs = { corn=25 }, outputs = { gene_harden=1 }, time = 5.5},
{inputs = { crystalplant=25 }, outputs = { gene_stealth=1 }, time = 5.5},
{inputs = { currentcorn=25 }, outputs = { gene_mimetic=1 }, time = 5.5},
{inputs = { diodia=25 }, outputs = { gene_assimilate=1 }, time = 5.5},
{inputs = { dirturchin=25 }, outputs = { gene_muscle=1 }, time = 5.5},
{inputs = { eggshoot=25 }, outputs = { gene_avian=1 }, time = 5.5},
{inputs = { feathercrown=25 }, outputs = { gene_stimulant=1 }, time = 5.5},
{inputs = { grapes=25 }, outputs = { gene_resist=1 }, time = 5.5},
{inputs = { greenapple=25 }, outputs = { gene_regen=1 }, time = 5.5},
{inputs = { kelp=25 }, outputs = { gene_regen=1 }, time = 5.5},
{inputs = { kiwi=25 }, outputs = { gene_harden=1 }, time = 5.5},
{inputs = { neonmelon=25 }, outputs = { gene_assimilate=1 }, time = 5.5},
{inputs = { oculemon=25 }, outputs = { gene_ocular=1 }, time = 5.5},
{inputs = { orange=25 }, outputs = { gene_regen=1 }, time = 5.5},
{inputs = { pearlpea=25 }, outputs = { gene_adaptivecell=1 }, time = 5.5},
{inputs = { pineapple=25 }, outputs = { gene_harden=1 }, time = 5.5},
{inputs = { potato=25 }, outputs = { gene_resist=1 }, time = 5.5},
{inputs = { pussplum=25 }, outputs = { gene_muscle=1 }, time = 5.5},
{inputs = { redapple=25 }, outputs = { gene_muscle=1 }, time = 5.5},
{inputs = { reefpod=25 }, outputs = { gene_aquacelerity=1 }, time = 5.5},
{inputs = { rice=25 }, outputs = { gene_defense=1 }, time = 5.5},
{inputs = { shroom=25 }, outputs = { gene_poisonous=1 }, time = 5.5},
{inputs = { sugar=25 }, outputs = { gene_stimulant=1 }, time = 5.5},
{inputs = { thornfruit=25 }, outputs = { gene_defense=1 }, time = 5.5},
{inputs = { tomato=25 }, outputs = { gene_nervebundle=1 }, time = 5.5},
{inputs = { toxictop=25 }, outputs = { gene_poisonous=1 }, time = 5.5},
{inputs = { wartweed=25 }, outputs = { gene_corrosive=1 }, time = 5.5},
{inputs = { wheat=25 }, outputs = { gene_chloroplast=1 }, time = 5.5},
{inputs = { wildvines=25 }, outputs = { gene_chloroplast=1 }, time = 5.5},
{inputs = { coconut=25 }, outputs = { gene_defense=1 }, time = 5.5}
}

function init(args)
    if args then return end
    self.timer = 1
    self.mintick = 1
    self.crafting = false
    self.output = {}
end

function getInputContents()
        local id = entity.id()
      
        local contents = {}
        for i=0,2 do
            local stack = world.containerItemAt(entity.id(),i)
            if stack ~=nil then
                if contents[stack.name] ~= nil then
                  contents[stack.name] = contents[stack.name] + stack.count
                else
                  contents[stack.name] = stack.count
                end
            end
        end
      
        return contents
    end

function map(l,f)
    local res = {}
    for k,v in pairs(l) do
        res[k] = f(v)
    end
    return res
end

function filter(l,f)
  return map(l, function(e) return f(e) and e or nil end)
end

function getValidRecipes(query)

    local function subset(t1,t2)
        if next(t2) == nil then 
          return false 
        end
        if t1 == t2 then 
          return true
        end
            for k,_ in pairs(t1) do
                if not t2[k] or t1[k] > t2[k] then 
                  return false 
                end
            end
        return true
    end

return filter(recipes, function(l) return subset(l.inputs, query) end)

end


function getOutSlotsFor(something)
    local empty = {} -- empty slots in the outputs
    local slots = {} -- slots with a stack of "something"

    for i = 3, 11 do -- iterate all output slots
        local stack = world.containerItemAt(entity.id(), i) -- get the stack on i
        if stack ~= nil then -- not empty
            if stack.name == something then -- its "something"
                table.insert(slots,i) -- possible drop slot
            end
        else -- empty
            table.insert(empty, i)
        end
    end

    for _,e in pairs(empty) do -- add empty slots to the end
        table.insert(slots,e)
    end
    return slots
end


function update(dt)
    self.timer = self.timer - dt
    if self.timer <= 0 then
        if self.crafting then
            for k,v in pairs(self.output) do
                local leftover = {name = k, count = v}
                local slots = getOutSlotsFor(k)
                for _,i in pairs(slots) do
                    leftover = world.containerPutItemsAt(entity.id(), leftover, i)
                    if leftover == nil then
                        break
                    end
                end

                if leftover ~= nil then
                    world.spawnItem(leftover.name, entity.position(), leftover.count)
                end
            end
            self.crafting = false
            self.output = {}
            self.timer = self.mintick --reset timer to a safe minimum
            animator.setAnimationState("samplingarrayanim", "idle")
        end

        if not self.crafting and self.timer <= 0 then --make sure we didn't just finish crafting
            if not startCrafting(getValidRecipes(getInputContents())) then self.timer = self.mintick end --set timeout if there were no recipes
        end
    end
end



function startCrafting(result)
    if next(result) == nil then return false
    else _,result = next(result)

        for k,v in pairs(result.inputs) do
            if not world.containerConsume(entity.id(), {item = k , count = v}) then return false end
        end

        self.crafting = true
        self.timer = result.time
        self.output = result.outputs
        animator.setAnimationState("samplingarrayanim", "working")

        return true
    end              
end

local recipes = {
{inputs = { mushroomseed=1 }, outputs = { gene_regen=1 }, time = 1.2},
{inputs = { kirifruitseed=1 }, outputs = { gene_energy=1 }, time = 1.2},
{inputs = { nakatiseed=1 }, outputs = { gene_defense=1 }, time = 1.2},
{inputs = { piruseed=1 }, outputs = { gene_agility=1 }, time = 1.2},
{inputs = { avaliplant1=1 }, outputs = { gene_energy=1 }, time = 1.2},
{inputs = { avaliplant2=1 }, outputs = { gene_defense=1 }, time = 1.2},
{inputs = { avaliplant3=1 }, outputs = { gene_agility=1 }, time = 1.2},
{inputs = { wildkirifruitseed=1 }, outputs = { gene_energy=1 }, time = 1.2},
{inputs = { wildnakatiseed=1 }, outputs = { gene_defense=1 }, time = 1.2},
{inputs = { wildpiruseed=1 }, outputs = { gene_agility=1 }, time = 1.2},
{inputs = { reedseed=1 }, outputs = { gene_assimilate=1 }, time = 1.2},
{inputs = { wildreedseed=1 }, outputs = { gene_assimilate=1 }, time = 1.2},
{inputs = { cottonseed=1 }, outputs = { gene_energy=1 }, time = 1.2},
{inputs = { wildcottonseed=1 }, outputs = { gene_energy=1 }, time = 1.2},
{inputs = { cocoaseed=1 }, outputs = { gene_energy=1 }, time = 1.2},
{inputs = { wildcocoaseed=1 }, outputs = { gene_energy=1 }, time = 1.2},
{inputs = { shroomblockglow=50 }, outputs = { gene_bioluminescent=1 }, time = 1.2},
{inputs = { biospore=4 }, outputs = { gene_bioluminescent=1 }, time = 1.2},
{inputs = { hopsseed=1 }, outputs = { gene_stimulant=1 }, time = 1.2},
{inputs = { cinnamonseed=1 }, outputs = { gene_stimulant=1 }, time = 1.2},
{inputs = { automatoseed=1 }, outputs = { gene_harden=1 }, time = 1.2},
{inputs = { avesmingoseed=1 }, outputs = { gene_chloroplast=1 }, time = 1.2},
{inputs = { bananaseed=1 }, outputs = { gene_resist=1 }, time = 1.2},
{inputs = { beakseedseed=1 }, outputs = { gene_avian=1 }, time = 1.2},
{inputs = { boltbulbseed=1 }, outputs = { gene_reactive=1 }, time = 1.2},
{inputs = { bonebooseed=1 }, outputs = { gene_skeletal=1 }, time = 1.2},
{inputs = { brackentreeseed=1 }, outputs = { gene_reproductive=1 }, time = 1.2},
{inputs = { carrotseed=1 }, outputs = { gene_resist=1 }, time = 1.2},
{inputs = { chiliseed=1 }, outputs = { gene_pyro=1 }, time = 1.2},
{inputs = { coffeeseed=1 }, outputs = { gene_energy=1 }, time = 1.2},
{inputs = { coralcreepseed=1 }, outputs = { gene_aquahomeo=1 }, time = 1.2},
{inputs = { cornseed=1 }, outputs = { gene_harden=1 }, time = 1.2},
{inputs = { crystalplantseed=1 }, outputs = { gene_stealth=1 }, time = 1.2},
{inputs = { currentcornseed=1 }, outputs = { gene_mimetic=1 }, time = 1.2},
{inputs = { diodiaseed=1 }, outputs = { gene_assimilate=1 }, time = 1.2},
{inputs = { dirturchinseed=1 }, outputs = { gene_muscle=1 }, time = 1.2},
{inputs = { eggshootseed=1 }, outputs = { gene_avian=1 }, time = 1.2},
{inputs = { feathercrownseed=1 }, outputs = { gene_stimulant=1 }, time = 1.2},
{inputs = { flowerblack=1 }, outputs = { gene_muscle=1 }, time = 1.2},
{inputs = { flowerbrown=1 }, outputs = { gene_energy=1 }, time = 1.2},
{inputs = { flowergreen=1 }, outputs = { gene_skeletal=1 }, time = 1.2},
{inputs = { flowergrey=1 }, outputs = { gene_reproductive=1 }, time = 1.2},
{inputs = { flowerorange=1 }, outputs = { gene_avian=1 }, time = 1.2},
{inputs = { flowerorchid=1 }, outputs = { gene_resist=1 }, time = 1.2},
{inputs = { flowerorchid2=1 }, outputs = { gene_resist=1 }, time = 1.2},
{inputs = { flowerorchid3=1 }, outputs = { gene_resist=1 }, time = 1.2},
{inputs = { flowerpink=1 }, outputs = { gene_aquahomeo=1 }, time = 1.2},
{inputs = { flowerpurple=1 }, outputs = { gene_assimilate=1 }, time = 1.2},
{inputs = { flowerwhite=1 }, outputs = { gene_mimetic=1 }, time = 1.2},
{inputs = { flowerblue=1 }, outputs = { gene_nervebundle=1 }, time = 1.2},
{inputs = { flowerred=1 }, outputs = { gene_regen=1 },  time = 1.2},
{inputs = { floweryellow=1 }, outputs = { gene_reproductive=1 }, time = 1.2},
{inputs = { flowerspring=1 }, outputs = { gene_reproductive=1 }, time = 1.2},
{inputs = { grapesseed=1 }, outputs = { gene_resist=1 }, time = 1.2},
{inputs = { kiwiseed=1 }, outputs = { gene_harden=1 }, time = 1.2},
{inputs = { neonmelonseed=1 }, outputs = { gene_assimilate=1 }, time = 1.2},
{inputs = { oculemonseed=1 }, outputs = { gene_ocular=1 }, time = 1.2},
{inputs = { pearlpeaseed=1 }, outputs = { gene_adaptivecell=1 }, time = 1.2},
{inputs = { pineappleseed=1 }, outputs = { gene_harden=1 }, time = 1.2},
{inputs = { potatoseed=1 }, outputs = { gene_resist=1 }, time = 1.2},
{inputs = { pussplumseed=1 }, outputs = { gene_muscle=1 }, time = 1.2},
{inputs = { reefpodseed=1 }, outputs = { gene_aquacelerity=1 }, time = 1.2},
{inputs = { riceseed=1 }, outputs = { gene_defense=1 }, time = 1.2},
{inputs = { sapling=1 }, outputs = { gene_harden=1 }, time = 1.2},
{inputs = { sugarcaneseed=1 }, outputs = { gene_stimulant=1 }, time = 1.2},
{inputs = { tomatoseed=1 }, outputs = { gene_nervebundle=1 }, time = 1.2},
{inputs = { toxictopseed=1 }, outputs = { gene_poisonous=1 }, time = 1.2},
{inputs = { wartweedseed=1 }, outputs = { gene_corrosive=1 }, time = 1.2},
{inputs = { wheatseed=1 }, outputs = { gene_chloroplast=1 }, time = 1.2},
{inputs = { dragonsbeardseed=1 }, outputs = { gene_pyro=1 }, time = 1.2},
{inputs = { minkocoapodseed=1 }, outputs = { gene_mammal=1 }, time = 1.2},
{inputs = { itaseed=1 }, outputs = { gene_chloroplast=1 }, time = 1.2},
{inputs = { nissseed=1 }, outputs = { gene_immunity=1 }, time = 1.2},
{inputs = { energiflowerseed=1 }, outputs = { gene_energy=1 }, time = 1.2},
{inputs = { lactariusindigoseed=1 }, outputs = { gene_reproductive=1 }, time = 1.2},
{inputs = { greenleafseed=1 }, outputs = { gene_chloroplast=1 }, time = 1.2},
{inputs = { guamseed=1 }, outputs = { gene_immunity=1 }, time = 1.2},
{inputs = { miraclegrassseed=1 }, outputs = { gene_regen=1 }, time = 1.2},
{inputs = { algaeseed=1 }, outputs = { gene_reproductive=1 }, time = 1.2},
{inputs = { bloodrootseed=1 }, outputs = { gene_regen=1 }, time = 1.2},
{inputs = { jillyrootseed=1 }, outputs = { gene_chloroplast=1 }, time = 1.2},
{inputs = { thornitoxseed=1 }, outputs = { gene_corrosive=1 }, time = 1.2},
{inputs = { wubstemseed=1 }, outputs = { gene_adaptivecell=1 }, time = 1.2},
{inputs = { darklightflower=1 }, outputs = { gene_immunity=1 }, time = 1.2},
{inputs = { goldenseaspongeplant=1 }, outputs = { gene_fish=1 }, time = 5},
{inputs = { fuspongeweedseed=1 }, outputs = { gene_fish=1 }, time = 5},
{inputs = { fusnowberryseed=1 }, outputs = { gene_cryo=1 }, time = 5},
{inputs = { garpberryseed=1 }, outputs = { gene_resist=1 }, time = 2},
{inputs = { varanberryseed=1 }, outputs = { gene_regen=1 }, time = 1.2},
{inputs = { cellpodsplant=1 }, outputs = { gene_insectoid=5 }, time = 5},
{inputs = { kamaranpodsplant=1 }, outputs = { gene_mimetic=4 }, time = 5},
{inputs = { tinselbush=1 }, outputs = { gene_reactive=1 }, time = 1.2},
{inputs = { poetree=1 }, outputs = { gene_assimilate=1 }, time = 1.2},
{inputs = { whitespine=1 }, outputs = { gene_immunity=1 }, time = 1.2},
{inputs = { isn_meatplant=1 }, outputs = { gene_void=1 }, time = 1.2},
{inputs = { mintseed=1 }, outputs = { gene_agility=1 }, time = 1.2},
{inputs = { onionseed=1 }, outputs = { gene_agility=1 }, time = 1.2},
{inputs = { yellowfootseed=1 }, outputs = { gene_energy=1 }, time = 1.2},
{inputs = { caprioleplantseed=1 }, outputs = { gene_muscle=1 }, time = 1.2},
{inputs = { petrifiedrootseed=1 }, outputs = { gene_void=1 }, time = 1.2},
{inputs = { littlegoodberryseed=1 }, outputs = { gene_regen=1 }, time = 1.2},
{inputs = { vanusflowerseed=1 }, outputs = { gene_defense=1 }, time = 1.2},
{inputs = { slimeplantseed=1 }, outputs = { gene_resist=1 }, time = 1.2},
{inputs = { stranglevineseed=1 }, outputs = { gene_reactive=1 }, time = 1.2},
{inputs = { ghostmushroomseed=1 }, outputs = { gene_stealth=1 }, time = 1.2},
{inputs = { goldshroomseed=1 }, outputs = { gene_harden=1 }, time = 1.2},
{inputs = { beeflowerseed=1 }, outputs = { gene_reproductive=1, gene_regen=1 }, time = 1.2 },
{inputs = { beetlesproutseed=1 }, outputs = { gene_harden=2, gene_insectoid=2 }, time = 1.2},
{inputs = { biscornseed=1 }, outputs = { gene_nervebundle=1 }, time = 1.2},
{inputs = { blizzberryseed=1 }, outputs = { gene_cryo=1 }, time = 1.2},
{inputs = { bluemelonseed=1 }, outputs = { gene_energy=1 }, time = 1.2},
{inputs = { blexplantseed=1 }, outputs = { gene_energy=1 }, time = 1.2},
{inputs = { aquapodseed=1 }, outputs = { gene_aquahomeo=1, gene_aquacelerity=1 }, time = 1.2},
{inputs = { bambooseed=1 }, outputs = { gene_reproductive=1 }, time = 1 },
{inputs = { blisterbushplantseed=1 }, outputs = { gene_bioluminescent=1 }, time = 1.2},
{inputs = { corvexseed=1 }, outputs = { gene_corrosive=1 }, time = 1.2},
{inputs = { deathblossomseed=1 }, outputs = { gene_poisonous=2 }, time = 1.2},
{inputs = { diodiahybridseed=1 }, outputs = { gene_mimetic=1 }, time = 1.2},
{inputs = { erithianalgaeseed=1 }, outputs = { gene_insectoid=1 }, time = 1.2},
{inputs = { floralytplantseed=1 }, outputs = { gene_regen=4 }, time = 1.2},
{inputs = { fubioshroomblue=1 }, outputs = { biospore=3 }, time = 1.2},
{inputs = { fubioshroomgreen=1 }, outputs = { biospore=3 }, time = 1.2},
{inputs = { fubioshroompurple=1 }, outputs = { biospore=3 }, time = 1.2},
{inputs = { fubioshroomred=1 }, outputs = { biospore=3 }, time = 1.2},
{inputs = { fubioshroomyellow=1 }, outputs = { biospore=3 }, time = 1.2},
{inputs = { fayshroomseed=1 }, outputs = { gene_stealth=1 }, time = 1.2},
{inputs = { ginsengseed=1 }, outputs = { gene_regen=1 }, time = 1.2},
{inputs = { goldenrootseed=1 }, outputs = { gene_mimetic=1 }, time = 1.2},
{inputs = { gazelemonseed=1 }, outputs = { gene_ocular=1 }, time = 1.2},
{inputs = { glarestalkseed=1 }, outputs = { gene_ocular=2 }, time = 1.2},
{inputs = { genesiberryseed=1 }, outputs = { gene_assimilate=3 }, time = 1.2},
{inputs = { goldenglowseed=1 }, outputs = { gene_bioluminescent=2 }, time = 1.2},
{inputs = { haleflowerseed=1 }, outputs = { gene_energy=4 }, time = 1.2},
{inputs = { hellfireplantseed=1 }, outputs = { gene_pyro=3 }, time = 1.2},
{inputs = { ighantseed=1 }, outputs = { gene_stimulant=1 }, time = 1.2},
{inputs = { ignuschiliseed=1 }, outputs = { gene_pyro=1, gene_reactive=1 }, time = 1.2},
{inputs = { ignuschili2seed=1 }, outputs = { gene_pyro=2, gene_reactive=2 }, time = 1.2},
{inputs = { lasherplantseed=1 }, outputs = { gene_rage=1 }, time = 1.2},
{inputs = { leafshellseed=1 }, outputs = { gene_defense=1 }, time = 1.2},
{inputs = { littlerascalseed=1 }, outputs = { gene_defense=2 }, time = 1.2},
{inputs = { melodistarseed=1 }, outputs = { gene_energy=2 }, time = 1.2},
{inputs = { mireurchinseed=1 }, outputs = { gene_agility=1 }, time = 1.2},
{inputs = { mutaviskseed=1 }, outputs = { gene_agility=1 }, time = 1.2},
{inputs = { naileryseed=1 }, outputs = { gene_reactive=1 }, time = 1.2},
{inputs = { neuropodseed=1 }, outputs = { gene_mimetic=2 }, time = 1.2},
{inputs = { oonfortaseed=1 }, outputs = { gene_bioluminescent=1 }, time = 1.2},
{inputs = { pasakavineseed=1 }, outputs = { gene_insectoid=1 }, time = 1.2},
{inputs = { pekkitseed=1 }, outputs = { gene_cryo=1 }, time = 1.2},
{inputs = { pinkloomseed=1 }, outputs = { gene_rage=1 }, time = 1.2},
{inputs = { porphisplantseed=1 }, outputs = { gene_muscle=1 }, time = 1.2},
{inputs = { rockrootseed=1 }, outputs = { gene_harden=4 }, time = 1.2},
{inputs = { shinyacornseed=1 }, outputs = { gene_defense=1 }, time = 1.2},
{inputs = { shockshroomseed=1 }, outputs = { gene_electric=2 }, time = 1.2},
{inputs = { silverleafseed=1 }, outputs = { gene_energy=1 }, time = 1.2},
{inputs = { springvaultseed=1 }, outputs = { gene_muscle=2 }, time = 1.2},
{inputs = { teratomatoseed=1 }, outputs = { gene_regen=3 }, time = 1.2},
{inputs = { talonseedseed=1 }, outputs = { gene_resist=1 }, time = 1.2},
{inputs = { tetherhookseed=1 }, outputs = { gene_void=2 }, time = 1.2},
{inputs = { tyvokkseed=1 }, outputs = { gene_immunity=1 }, time = 1.2},
{inputs = { vextongueseed=1 }, outputs = { gene_energy=1 }, time = 1.2},
{inputs = { voritseed=1 }, outputs = { gene_aquacelerity=2 }, time = 1.2},
{inputs = { vashtaplantseed=1 }, outputs = { gene_insectoid=1 }, time = 1.2},
{inputs = { wretchelseed=1 }, outputs = { gene_void=3 }, time = 1.2},
{inputs = { xaxseed=1 }, outputs = { gene_avian=3 }, time = 1.2},
{inputs = { zathiseed=1 }, outputs = { gene_avian=2 }, time = 1.2},
{inputs = { aenemaflower=1 }, outputs = { gene_energy=2 }, time = 1.2},
{inputs = { arkaentree=1 }, outputs = { gene_harden=2 }, time = 1.2},
{inputs = { batterystem=1 }, outputs = { gene_electric=2 }, time = 1.2},
{inputs = { bellamorte=1 }, outputs = { gene_poisonous=2 }, time = 1.2},
{inputs = { bladetree=1 }, outputs = { gene_reactive=2 }, time = 1.2},
{inputs = { crystallite=1 }, outputs = { gene_mimetic=2 }, time = 1.2},
{inputs = { fletchweed=1 }, outputs = { gene_chloroplast=2 }, time = 1.2},
{inputs = { garikleaf=1 }, outputs = { gene_regen=2 }, time = 1.2},
{inputs = { herrodbush=1 }, outputs = { gene_agility=2 }, time = 1.2},
{inputs = { kramil=1 }, outputs = { gene_immunity=2 }, time = 1.2},
{inputs = { quellstem=1 }, outputs = { gene_resist=2 }, time = 1.2},
{inputs = { victorleaf=1 }, outputs = { gene_muscle=2 }, time = 1.2},
{inputs = { tentacleplant=1 }, outputs = { gene_mimetic=2 }, time = 1.2},
{inputs = { fuavikancactusseed=1 }, outputs = { gene_defense=1 }, time = 1.2},
{inputs = { fuavikanspiceplantseed=1 }, outputs = { gene_mimetic=1 }, time = 1.2},
{inputs = { wildfuavikancactusseed=1 }, outputs = { gene_defense=1 }, time = 1.2},
{inputs = { wildfuavikanspiceplantseed=1 }, outputs = { gene_mimetic=1 }, time = 1.2},
{inputs = { wildcinnamonseed=1 }, outputs = { gene_stimulant=1 }, time = 1.2},
{inputs = { wildautomatoseed=1 }, outputs = { gene_harden=1 }, time = 1.2},
{inputs = { wildavesmingoseed=1 }, outputs = { gene_chloroplast=1 }, time = 1.2},
{inputs = { wildbananaseed=1 }, outputs = { gene_resist=1 }, time = 1.2},
{inputs = { wildbeakseedseed=1 }, outputs = { gene_avian=1 }, time = 1.2},
{inputs = { wildboltbulbseed=1 }, outputs = { gene_reactive=1 }, time = 1.2},
{inputs = { wildbonebooseed=1 }, outputs = { gene_skeletal=1 }, time = 1.2},
{inputs = { wildbrackentreeseed=1 }, outputs = { gene_reproductive=1 }, time = 1.2},
{inputs = { wildcarrotseed=1 }, outputs = { gene_resist=1 }, time = 1.2},
{inputs = { wildchiliseed=1 }, outputs = { gene_pyro=1 }, time = 1.2},
{inputs = { wildcoffeeseed=1 }, outputs = { gene_energy=1 }, time = 1.2},
{inputs = { wildcoralcreepseed=1 }, outputs = { gene_aquahomeo=1 }, time = 1.2},
{inputs = { wildcornseed=1 }, outputs = { gene_harden=1 }, time = 1.2},
{inputs = { wildcrystalplantseed=1 }, outputs = { gene_stealth=1 }, time = 1.2},
{inputs = { wildcurrentcornseed=1 }, outputs = { gene_mimetic=1 }, time = 1.2},
{inputs = { wilddiodiaseed=1 }, outputs = { gene_assimilate=1 }, time = 1.2},
{inputs = { wilddirturchinseed=1 }, outputs = { gene_muscle=1 }, time = 1.2},
{inputs = { wildeggshootseed=1 }, outputs = { gene_avian=1 }, time = 1.2},
{inputs = { wildfeathercrownseed=1 }, outputs = { gene_stimulant=1 }, time = 1.2},
{inputs = { wildflowerblue=1 }, outputs = { gene_nervebundle=1 }, time = 1.2},
{inputs = { wildflowerred=1 }, outputs = { gene_stimulant=1 }, time = 1.2},
{inputs = { wildfloweryellow=1 }, outputs = { gene_reproductive=1 }, time = 1.2},
{inputs = { wildflowerspring=1 }, outputs = { gene_reproductive=1 }, time = 1.2},
{inputs = { wildgrapesseed=1 }, outputs = { gene_resist=1 }, time = 1.2},
{inputs = { wildhopsseed=1 }, outputs = { gene_reactive=1 }, time = 1.2},
{inputs = { wildkiwiseed=1 }, outputs = { gene_harden=1 }, time = 1.2},
{inputs = { wildneonmelonseed=1 }, outputs = { gene_assimilate=1 }, time = 1.2},
{inputs = { wildoculemonseed=1 }, outputs = { gene_ocular=1 }, time = 1.2},
{inputs = { wildpearlpeaseed=1 }, outputs = { gene_adaptivecell=1 }, time = 1.2},
{inputs = { wildpineappleseed=1 }, outputs = { gene_harden=1 }, time = 1.2},
{inputs = { wildpotatoseed=1 }, outputs = { gene_resist=1 }, time = 1.2},
{inputs = { wildpussplumseed=1 }, outputs = { gene_muscle=1 }, time = 1.2},
{inputs = { wildreefpodseed=1 }, outputs = { gene_aquacelerity=1 }, time = 1.2},
{inputs = { wildriceseed=1 }, outputs = { gene_defense=1 }, time = 1.2},
{inputs = { wildsapling=1 }, outputs = { gene_harden=1 }, time = 1.2},
{inputs = { wildsugarcaneseed=1 }, outputs = { gene_stimulant=1 }, time = 1.2},
{inputs = { wildtomatoseed=1 }, outputs = { gene_nervebundle=1 }, time = 1.2},
{inputs = { wildtoxictopseed=1 }, outputs = { gene_poisonous=1 }, time = 1.2},
{inputs = { wildwartweedseed=1 }, outputs = { gene_corrosive=1 }, time = 1.2},
{inputs = { wildwheatseed=1 }, outputs = { gene_chloroplast=1 }, time = 1.2},
{inputs = { wilddragonsbeardseed=1 }, outputs = { gene_pyro=1 }, time = 1.2},
{inputs = { wildminkocoapodseed=1 }, outputs = { gene_mammal=1 }, time = 1.2},
{inputs = { wilditaseed=1 }, outputs = { gene_chloroplast=1 }, time = 1.2},
{inputs = { wildnissseed=1 }, outputs = { gene_immunity=1 }, time = 1.2},
{inputs = { wildenergiflowerseed=1 }, outputs = { gene_energy=1 }, time = 1.2},
{inputs = { wildlactariusindigoseed=1 }, outputs = { gene_reproductive=1 }, time = 1.2},
{inputs = { wildgreenleafseed=1 }, outputs = { gene_chloroplast=1 }, time = 1.2},
{inputs = { wildguamseed=1 }, outputs = { gene_immunity=1 }, time = 1.2},
{inputs = { wildmiraclegrassseed=1 }, outputs = { gene_regen=1 }, time = 1.2},
{inputs = { wildalgaeseed=1 }, outputs = { gene_reproductive=1 }, time = 1.2},
{inputs = { wildbloodrootseed=1 }, outputs = { gene_regen=1 }, time = 1.2},
{inputs = { wildjillyrootseed=1 }, outputs = { gene_chloroplast=1 }, time = 1.2},
{inputs = { wildthornitoxseed=1 }, outputs = { gene_corrosive=1 }, time = 1.2},
{inputs = { wildwubstemseed=1 }, outputs = { gene_adaptivecell=1 }, time = 1.2},
{inputs = { wilddarklightflower=1 }, outputs = { gene_immunity=1 }, time = 1.2},
{inputs = { wildgoldenseaspongeplant=1 }, outputs = { gene_fish=1 }, time = 5},
{inputs = { wildfuspongeweedseed=1 }, outputs = { gene_fish=1 }, time = 5},
{inputs = { wildfusnowberryseed=1 }, outputs = { gene_cryo=1 }, time = 5},
{inputs = { wildvaranberryseed=1 }, outputs = { gene_regen=1 }, time = 1.2},
{inputs = { wildcellpodsplant=1 }, outputs = { gene_insectoid=5 }, time = 5},
{inputs = { wildkamaranpodsplant=1 }, outputs = { gene_mimetic=4 }, time = 5},
{inputs = { wildtinselbush=1 }, outputs = { gene_reactive=1 }, time = 1.2},
{inputs = { wildpoetree=1 }, outputs = { gene_assimilate=1 }, time = 1.2},
{inputs = { wildwhitespine=1 }, outputs = { gene_immunity=1 }, time = 1.2},
{inputs = { wildisn_meatplant=1 }, outputs = { gene_void=1 }, time = 1.2},
{inputs = { wildmintseed=1 }, outputs = { gene_agility=1 }, time = 1.2},
{inputs = { wildonionseed=1 }, outputs = { gene_agility=1 }, time = 1.2},
{inputs = { wildyellowfootseed=1 }, outputs = { gene_energy=1 }, time = 1.2},
{inputs = { wildcaprioleplantseed=1 }, outputs = { gene_muscle=1 }, time = 1.2},
{inputs = { wildpetrifiedrootseed=1 }, outputs = { gene_void=1 }, time = 1.2},
{inputs = { wildlittlegoodberryseed=1 }, outputs = { gene_regen=1 }, time = 1.2},
{inputs = { wildvanusflowerseed=1 }, outputs = { gene_defense=1 }, time = 1.2},
{inputs = { wildslimeplantseed=1 }, outputs = { gene_resist=1 }, time = 1.2},
{inputs = { wildstranglevineseed=1 }, outputs = { gene_reactive=1 }, time = 1.2},
{inputs = { wildghostmushroomseed=1 }, outputs = { gene_stealth=1 }, time = 1.2},
{inputs = { wildgoldshroomseed=1 }, outputs = { gene_harden=1 }, time = 1.2},
{inputs = { wildbeeflowerseed=1 }, outputs = { gene_reproductive=1, gene_regen=1 }, time = 1.2 },
{inputs = { wildbeetlesproutseed=1 }, outputs = { gene_harden=2, gene_insectoid=2 }, time = 1.2},
{inputs = { wildbiscornseed=1 }, outputs = { gene_nervebundle=1 }, time = 1.2},
{inputs = { wildblizzberryseed=1 }, outputs = { gene_cryo=1 }, time = 1.2},
{inputs = { wildbluemelonseed=1 }, outputs = { gene_energy=1 }, time = 1.2},
{inputs = { wildblexplantseed=1 }, outputs = { gene_energy=1 }, time = 1.2},
{inputs = { wildaquapodseed=1 }, outputs = { gene_aquahomeo=1, gene_aquacelerity=1 }, time = 1.2},
{inputs = { wildbambooseed=1 }, outputs = { gene_reproductive=1 }, time = 1 },
{inputs = { wildblisterbushplantseed=1 }, outputs = { gene_bioluminescent=1 }, time = 1.2},
{inputs = { wildcorvexseed=1 }, outputs = { gene_corrosive=1 }, time = 1.2},
{inputs = { wilddeathblossomseed=1 }, outputs = { gene_poisonous=2 }, time = 1.2},
{inputs = { wilddiodiahybridseed=1 }, outputs = { gene_mimetic=1 }, time = 1.2},
{inputs = { wilderithianalgaeseed=1 }, outputs = { gene_insectoid=1 }, time = 1.2},
{inputs = { wildfloralytplantseed=1 }, outputs = { gene_regen=4 }, time = 1.2},
{inputs = { wildfubioshroomblue=1 }, outputs = { biospore=3 }, time = 1.2},
{inputs = { wildfubioshroomgreen=1 }, outputs = { biospore=3 }, time = 1.2},
{inputs = { wildfubioshroompurple=1 }, outputs = { biospore=3 }, time = 1.2},
{inputs = { wildfubioshroomred=1 }, outputs = { biospore=3 }, time = 1.2},
{inputs = { wildfubioshroomyellow=1 }, outputs = { biospore=3 }, time = 1.2},
{inputs = { wildfayshroomseed=1 }, outputs = { gene_stealth=1 }, time = 1.2},
{inputs = { wildginsengseed=1 }, outputs = { gene_regen=1 }, time = 1.2},
{inputs = { wildgoldenrootseed=1 }, outputs = { gene_mimetic=1 }, time = 1.2},
{inputs = { wildgazelemonseed=1 }, outputs = { gene_ocular=1 }, time = 1.2},
{inputs = { wildglarestalkseed=1 }, outputs = { gene_ocular=2 }, time = 1.2},
{inputs = { wildgenesiberryseed=1 }, outputs = { gene_assimilate=3 }, time = 1.2},
{inputs = { wildgoldenglowseed=1 }, outputs = { gene_bioluminescent=2 }, time = 1.2},
{inputs = { wildhaleflowerseed=1 }, outputs = { gene_energy=4 }, time = 1.2},
{inputs = { wildhellfireplantseed=1 }, outputs = { gene_pyro=3 }, time = 1.2},
{inputs = { wildighantseed=1 }, outputs = { gene_stimulant=1 }, time = 1.2},
{inputs = { wildignuschiliseed=1 }, outputs = { gene_pyro=2 }, time = 1.2},
{inputs = { wildignuschili2seed=1 }, outputs = { gene_pyro=3 }, time = 1.2},
{inputs = { wildlasherplantseed=1 }, outputs = { gene_rage=1 }, time = 1.2},
{inputs = { wildleafshellseed=1 }, outputs = { gene_defense=1 }, time = 1.2},
{inputs = { wildlittlerascalseed=1 }, outputs = { gene_defense=2 }, time = 1.2},
{inputs = { wildmelodistarseed=1 }, outputs = { gene_energy=2 }, time = 1.2},
{inputs = { wildmireurchinseed=1 }, outputs = { gene_agility=1 }, time = 1.2},
{inputs = { wildmutaviskseed=1 }, outputs = { gene_agility=1 }, time = 1.2},
{inputs = { wildnaileryseed=1 }, outputs = { gene_reactive=1 }, time = 1.2},
{inputs = { wildneuropodseed=1 }, outputs = { gene_mimetic=2 }, time = 1.2},
{inputs = { wildoonfortaseed=1 }, outputs = { gene_bioluminescent=1 }, time = 1.2},
{inputs = { wildpasakavineseed=1 }, outputs = { gene_insectoid=1 }, time = 1.2},
{inputs = { wildpekkitseed=1 }, outputs = { gene_cryo=1 }, time = 1.2},
{inputs = { wildpinkloomseed=1 }, outputs = { gene_rage=1 }, time = 1.2},
{inputs = { wildporphisplantseed=1 }, outputs = { gene_muscle=1 }, time = 1.2},
{inputs = { wildrockrootseed=1 }, outputs = { gene_harden=4 }, time = 1.2},
{inputs = { wildshinyacornseed=1 }, outputs = { gene_defense=1 }, time = 1.2},
{inputs = { wildshockshroomseed=1 }, outputs = { gene_electric=2 }, time = 1.2},
{inputs = { wildsilverleafseed=1 }, outputs = { gene_energy=1 }, time = 1.2},
{inputs = { wildspringvaultseed=1 }, outputs = { gene_muscle=2 }, time = 1.2},
{inputs = { wildteratomatoseed=1 }, outputs = { gene_regen=3 }, time = 1.2},
{inputs = { wildtalonseedseed=1 }, outputs = { gene_resist=1 }, time = 1.2},
{inputs = { wildtetherhookseed=1 }, outputs = { gene_void=2 }, time = 1.2},
{inputs = { wildtyvokkseed=1 }, outputs = { gene_immunity=1 }, time = 1.2},
{inputs = { wildvextongueseed=1 }, outputs = { gene_energy=1 }, time = 1.2},
{inputs = { wildvoritseed=1 }, outputs = { gene_aquacelerity=2 }, time = 1.2},
{inputs = { wildvashtaplantseed=1 }, outputs = { gene_insectoid=1 }, time = 1.2},
{inputs = { wildwretchelseed=1 }, outputs = { gene_void=3 }, time = 1.2},
{inputs = { wildxaxseed=1 }, outputs = { gene_avian=3 }, time = 1.2},
{inputs = { wildzathiseed=1 }, outputs = { gene_avian=2 }, time = 1.2},
{inputs = { wildaenemaflower=1 }, outputs = { gene_energy=2 }, time = 1.2},
{inputs = { wildarkaentree=1 }, outputs = { gene_harden=2 }, time = 1.2},
{inputs = { wildbatterystem=1 }, outputs = { gene_electric=2 }, time = 1.2},
{inputs = { wildbellamorte=1 }, outputs = { gene_poisonous=2 }, time = 1.2},
{inputs = { wildbladetree=1 }, outputs = { gene_reactive=2 }, time = 1.2},
{inputs = { wildcrystallite=1 }, outputs = { gene_mimetic=2 }, time = 1.2},
{inputs = { wildfletchweed=1 }, outputs = { gene_chloroplast=2 }, time = 1.2},
{inputs = { wildgarikleaf=1 }, outputs = { gene_regen=2 }, time = 1.2},
{inputs = { wildherrodbush=1 }, outputs = { gene_agility=2 }, time = 1.2},
{inputs = { wildkramil=1 }, outputs = { gene_immunity=2 }, time = 1.2},
{inputs = { wildquellstem=1 }, outputs = { gene_resist=2 }, time = 1.2},
{inputs = { wildvictorleaf=1 }, outputs = { gene_muscle=2 }, time = 1.2},
{inputs = { wildtentacleplant=1 }, outputs = { gene_mimetic=2 }, time = 1.2},

--produce
{inputs = { glowfibre=25 }, outputs = { gene_bioluminescent=1 }, time = 1.2},
{inputs = { plantfibre=25 }, outputs = { gene_reproductive=1 }, time = 1.2},
{inputs = { alienfruit=25 }, outputs = { gene_stimulant=1 }, time = 1.2},
{inputs = { automato=25 }, outputs = { gene_harden=1 }, time = 1.2},
{inputs = { avesmingo=25 }, outputs = { gene_chloroplast=1 }, time = 1.2},
{inputs = { banana=25 }, outputs = { gene_resist=1 }, time = 1.2},
{inputs = { boneboo=25 }, outputs = { gene_skeletal=1 }, time = 1.2},
{inputs = { cacti=25 }, outputs = { gene_defense=1 }, time = 1.2},
{inputs = { chili=25 }, outputs = { gene_pyro=1 }, time = 1.2},
{inputs = { carrot=25 }, outputs = { gene_resist=1 }, time = 1.2},
{inputs = { coffeebeans=25 }, outputs = { gene_energy=1 }, time = 1.2},
{inputs = { coralcreep=25 }, outputs = { gene_aquahomeo=1 }, time = 1.2},
{inputs = { corn=25 }, outputs = { gene_harden=1 }, time = 1.2},
{inputs = { crystalplant=25 }, outputs = { gene_stealth=1 }, time = 1.2},
{inputs = { currentcorn=25 }, outputs = { gene_mimetic=1 }, time = 1.2},
{inputs = { diodia=25 }, outputs = { gene_assimilate=1 }, time = 1.2},
{inputs = { dirturchin=25 }, outputs = { gene_muscle=1 }, time = 1.2},
{inputs = { eggshoot=25 }, outputs = { gene_avian=1 }, time = 1.2},
{inputs = { feathercrown=25 }, outputs = { gene_stimulant=1 }, time = 1.2},
{inputs = { grapes=25 }, outputs = { gene_resist=1 }, time = 1.2},
{inputs = { greenapple=25 }, outputs = { gene_regen=1 }, time = 1.2},
{inputs = { kelp=25 }, outputs = { gene_regen=1 }, time = 1.2},
{inputs = { kiwi=25 }, outputs = { gene_harden=1 }, time = 1.2},
{inputs = { neonmelon=25 }, outputs = { gene_assimilate=1 }, time = 1.2},
{inputs = { oculemon=25 }, outputs = { gene_ocular=1 }, time = 1.2},
{inputs = { orange=25 }, outputs = { gene_regen=1 }, time = 1.2},
{inputs = { pearlpea=25 }, outputs = { gene_adaptivecell=1 }, time = 1.2},
{inputs = { pineapple=25 }, outputs = { gene_harden=1 }, time = 1.2},
{inputs = { potato=25 }, outputs = { gene_resist=1 }, time = 1.2},
{inputs = { pussplum=25 }, outputs = { gene_muscle=1 }, time = 1.2},
{inputs = { redapple=25 }, outputs = { gene_muscle=1 }, time = 1.2},
{inputs = { reefpod=25 }, outputs = { gene_aquacelerity=1 }, time = 1.2},
{inputs = { rice=25 }, outputs = { gene_defense=1 }, time = 1.2},
{inputs = { shroom=25 }, outputs = { gene_poisonous=1 }, time = 1.2},
{inputs = { sugar=25 }, outputs = { gene_stimulant=1 }, time = 1.2},
{inputs = { thornfruit=25 }, outputs = { gene_defense=1 }, time = 1.2},
{inputs = { tomato=25 }, outputs = { gene_nervebundle=1 }, time = 1.2},
{inputs = { toxictop=25 }, outputs = { gene_poisonous=1 }, time = 1.2},
{inputs = { wartweed=25 }, outputs = { gene_corrosive=1 }, time = 1.2},
{inputs = { wheat=25 }, outputs = { gene_chloroplast=1 }, time = 1.2},
{inputs = { wildvines=25 }, outputs = { gene_chloroplast=1 }, time = 1.2},
{inputs = { coconut=25 }, outputs = { gene_defense=1 }, time = 1.2}
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

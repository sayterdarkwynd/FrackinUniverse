require "/scripts/util.lua"

function init()
	storage.item = storage.item or false
end

function craftingRecipe(items)
	if #items ~= 1 then return end
	local item = items[1]
	--sb.logInfo(sb.printJson(items,1))
  
	if not item then return end
	
	if not item.parameters or 
		(not item.parameters.currentAugment 
			and not item.parameters.currentCollar 
			and not item.parameters.lureType 
			and not item.parameters.reelType) 
	then
		return
	elseif item.parameters.currentAugment and item.parameters.currentAugment.type == "back" then
	
		local augmentMap = config.getParameter("augmentMap",{}) --get the list of augments from the config. list must be formatted as {"augment.name" : "itemName"}. Any augment detected here spawns as a vanilla augment.
		local augment = {}
		local aug_param = copy(item.parameters.currentAugment)
		
		storage.item = copy(item)
		jremove(storage.item.parameters,"currentAugment")
		
		if augmentMap[aug_param.name] then --do we know wtf this is?
			augment = {
				name = augmentMap[aug_param.name],
				count = 1,
				parameters = {} --{augment = aug_param} --used to pass all parameters, made the things unstackable	
			}
			--sb.logInfo(sb.printJson(augment))
		else --we don't know wtf this is, spawn a custom thing.
			augment = {
				name = "thornsaugment",
				count = 1,
				parameters = {
					shortdescription = "Extracted Augment",
					inventoryIcon = aug_param.displayIcon,
					description = aug_param.displayName,
					augment = aug_param
				}
			}
		end
		
		animator.setAnimationState("healState","on")
		
		return{
			input = items,
			output = augment,
			duration = 1.0
		}
		
	elseif item.parameters.currentCollar then --code for the collars, a little more involved.
	
		local collarMap = config.getParameter("collarMap",{})
		local collar = {}
		local collar_param = copy(item.parameters.currentCollar)
		
		storage.item = copy(item)
		jremove(storage.item.parameters, "currentCollar")
		jremove(storage.item.parameters, "currentPets")
		jremove(storage.item.parameters.tooltipFields, "collarIconImage")
		jremove(storage.item.parameters.tooltipFields, "collarNameLabel")
		storage.item.parameters.tooltipFields.noCollarLabel = "NO COLLAR WORN"
		storage.item.parameters.podItemHasPriority = true
		
		if collarMap[collar_param.name] then
			collar = {
				name = collarMap[collar_param.name],
				count = 1,
				parameters = {}
			}
		else
			collar = {
				name = "bouncycollar",
				count = 1,
				parameters = {
					shortdescription = "Extracted Collar",
					inventoryIcon = collar_param.displayIcon,
					description = collar_param.displayName,
					collar = collar_param
				}
			}
		end
		
		animator.setAnimationState("healState","on")
		
		return{
			input = items,
			output = collar,
			duration = 1.0
		}
		
	elseif item.parameters.reelType then
		
		local reelMap = config.getParameter("reelMap",{})
		local reel = {}
		local reel_param = {
			reelName = item.parameters.reelName,
			reelType = item.parameters.reelType,
			reelIcon = item.parameters.reelIcon,
			reelParameters = copy(item.parameters.reelParameters),
			shortdescription = "Extracted Reel",
			inventoryIcon = item.parameters.reelIcon,
			description = item.parameters.reelName
		}
		
		storage.item = copy(item)
		jremove(storage.item.parameters,"reelName")
		jremove(storage.item.parameters,"reelType")
		jremove(storage.item.parameters,"reelIcon")
		jremove(storage.item.parameters,"reelParameters")
		
		if reelMap[reel_param.reelType] then
			reel = {
				name = reelMap[reel_param.reelType],
				count = 1,
				parameters = {}
			}
		else
			reel = {
				name = "fishingreelfast",
				count = 1,
				parameters = reel_param
			}
		end
		
		animator.setAnimationState("healState","on")
		
		return{
			input = items,
			output = reel,
			duration = 1.0
		}
		 
	elseif item.parameters.lureType then
		
		local lureMap = config.getParameter("lureMap",{})
		local lure = {}
		local lure_param = {
			lureName = item.parameters.lureName,
			lureType = item.parameters.lureType,
			lureIcon = item.parameters.lureIcon,
			lureProjectile = item.parameters.lureProjectile,
			shortdescription = "Extracted Lure",
			inventoryIcon = item.parameters.lureIcon,
			description = item.parameters.lureName
		}
		
		storage.item = copy(item)
		jremove(storage.item.parameters, "lureName")
		jremove(storage.item.parameters, "lureType")
		jremove(storage.item.parameters, "lureIcon")
		jremove(storage.item.parameters, "lureProjectile")
		
		if lureMap[item.parameters.lureType] then	
			lure = {
				name = lureMap[lure_param.lureType],
				count = 1,
				parameters = {}
			}
		else
			lure = {
				name = "fishinglurecontrol",
				count = 1,
				parameters = lure_param
			}
		end
		
		return{
			input = items,
			output = lure,
			duration = 1.0
		}
		
	else
		return
	end	
end

function update(dt)
	local powerOn = false
	local inventory = world.containerItems(entity.id())
  
  
  for _,item in pairs(inventory) do
    if item.parameters.currentAugment 
		or item.parameters.currentCollar
		or item.parameters.lureType
		or item.parameters.reelType
	then
      powerOn = true
      break
    end
  end
  
  if storage.item and not inventory[1] and inventory[2] then
	world.containerAddItems(entity.id(),storage.item)
	--sb.logInfo(sb.printJson(storage.item,1))
	storage.item = false
  end

  if powerOn then
    animator.setAnimationState("powerState", "on")
  else
    animator.setAnimationState("powerState", "off")
  end
end

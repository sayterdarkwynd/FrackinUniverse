
function init()
	playerUsing = nil
	selfWorking = nil

	playerWorkingEfficiency = nil
	selfWorkingEfficiency = nil
	status = ""
	progress = 0
	oldItem = nil
	
	message.setHandler("paneOpened", paneOpened)
	message.setHandler("paneClosed", paneClosed)
	message.setHandler("getStatus", getStatus)
	
	playerWorkingEfficiency = config.getParameter("playerWorkingEfficiency")
	selfWorkingEfficiency = config.getParameter("selfWorkingEfficiency")
	selfWorking = config.getParameter("selfWorking")
end

function update(dt)
	if playerUsing or selfWorking then
		local currentItem = world.containerItemAt(entity.id(), 0)
		
		if currentItem == nil then
			status = "^yellow;Waiting for a subject..."
			
		elseif compare(currentItem, oldItem) then	
			if root.itemHasTag(oldItem.name, "queen") or root.itemHasTag(oldItem.name, "youngQueen") then
				if oldItem.parameters.genomeInspected then
					status = "^green;Queen identified"
				else
					if playerUsing then
						progress = progress + (playerWorkingEfficiency * dt)
					else
						progress = progress + (selfWorkingEfficiency * dt)
					end
					
					progress = math.floor(progress * 100) * 0.01
					
					if progress >= 100 then
						progress = 0
						status = "^green;Queen identified"
						
						oldItem.parameters.genomeInspected = true
						world.containerTakeAt(entity.id(), 0)
						world.containerPutItemsAt(entity.id(), oldItem, 0)
					else
						status = "^cyan;"..progress.."%"
						-- ***** chance to gain research *****
						local randCheck = math.random(10)
						if randCheck == 1 then
						 local bonusValue = config.getParameter("bonusResearch",0)
						 world.spawnItem("fuscienceresource",entity.position(),5+bonusValue) -- Gain research as this is used
						end
					end
				end					
			else
				status = "^red;Invalid sample detected"
			end
		
		else
			progress = 0
			if not (root.itemHasTag(currentItem.name, "queen") or root.itemHasTag(currentItem.name, "youngQueen")) then
				status = "^red;Invalid sample detected"
			end			
		end
		
		oldItem = currentItem
	else
		script.setUpdateDelta(-1)
	end
end

-- Straight outta util.lua
-- because NOPE to copying an ENTIRE script just for one function
function compare(t1, t2)
	if t1 == t2 then return true end
	if type(t1) ~= type(t2) then return false end
	if type(t1) ~= "table" then return false end
	for k,v in pairs(t1) do if not compare(v, t2[k]) then return false end end
	for k,v in pairs(t2) do if not compare(v, t1[k]) then return false end end
	return true
end

function paneOpened()
	script.setUpdateDelta(config.getParameter("scriptDelta"))
	playerUsing = true
end

function paneClosed()
	playerUsing = nil
end

function getStatus()
	if status then return status end
end
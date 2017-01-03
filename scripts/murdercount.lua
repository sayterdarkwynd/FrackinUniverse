stats = {}

function stats.record(statistics)
    local record = {}
    
    for i, v in ipairs(stats.getRecordPaths()) do
        local val = statistics.stat(v)
        
        if (type(val) == "table") then
            record[v] = stats.getSize(val)
            record[v..".set"] = val
        else
            if not val then val = 0 end
            record[v] = val;
        end
    end
    
    for x, y in pairs(stats.getSumOps()) do
        local sum = 0
        
        for z, path in ipairs(y) do
			if record[path] then 
				sum = sum + record[path]
			end
        end

        record[x] = sum
    end
    
    for key, val in pairs(record) do
        root.setConfiguration("mstats_"..key, val)
    end
   
end

function stats.getRecordPaths()
    local paths = {
        "kill",
        "kill.entityType.monster",
        "kill.entityType.npc",
        "killInnocent",
        "kill.entityType.player"
    }
    
    local categories = root.assetJson("/items/categories.config")["labels"]
    
    for cat, desc in pairs(categories) do
        table.insert(paths, "item.category."..cat)
    end
    
    stats.paths = paths
    
    return paths
end

function stats.getSumOps()
    local sumOps = {}
    sumOps["uniqueFossils"] = {"itemSet.category.smallFossil", "itemSet.category.mediumFossil", "itemSet.category.largeFossil"}
    sumOps["uniqueArmours"] = {"itemSet.category.legarmour", "itemSet.category.chestarmour", "itemSet.category.headarmour"}

    return sumOps
end

function stats.getSize(set)
    local count = 0
    for _ in pairs(set) do count = count + 1 end
    return count
end

function stats.numberFormat(amount)
  if (amount == nil) then
    return 0
  end  

  local formatted = amount
  while true do  
    formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
    if (k==0) then
      break
    end
  end
  return formatted
end

function stats.getStat(path)
    return root.getConfiguration("mstats_" .. path)
end

function stats.hasStats()
    if stats.getStat("item.category.block") then
        return true
    else
        return false
    end        

end
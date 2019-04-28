local recipes =
{
--combos
{inputs = { wrappedbody=1,elderrelic2=1 }, outputs = { inferiorbrain=1,fuscienceresource=520,bone=8,leather=1,alienmeat=4,faceskin=1,rawribmeat=2,liquidelderfluid=120  }, time = 14.0},
{inputs = { wrappedbody=1,elderrelic10=1 }, outputs = { inferiorbrain=1,fumadnessresource=520,bone=8,leather=1,alienmeat=12,rawribmeat=2,liquidelderfluid=80  }, time = 14.0},

--mains
{inputs = { wrappedbody=1 }, outputs = { inferiorbrain=1,fuscienceresource=120,bone=8,leather=1,alienmeat=4,faceskin=1,rawribmeat=2,liquidblood=40 }, time = 14.0},
{inputs = { wrappedbodyputrid=1 }, outputs = { inferiorbrain=1,fumadnessresource=5,bone=8,leather=1,rottingfleshmaterial=4,slew2=12,biospore=2,liquidbioooze=40 }, time = 14.0},
{inputs = { wrappedbodyalien=1 }, outputs = { brain=1,fuprecursorresource=5,bone=8,leather=1,slew4=12,rawribmeat=2,cellmateria=4,liquidalienjuice=40 }, time = 14.0},
{inputs = { greghead=1 }, outputs = { fumadnessresource=1,inferiorbrain=1,bone=4,slew2=3}, time = 9.0},
{inputs = { faceskin=1 }, outputs = { fumadnessresource=1,liquidblood=2, slew2=1}, time = 7.0},
{inputs = { leather=1 }, outputs = { slew2=1}, time = 7.0},
{inputs = { hardenedcarapace=1 }, outputs = { slew2=1}, time = 7.0},
{inputs = { agaranichor=1 }, outputs = { fuscienceresource=5}, time = 7.0},
{inputs = { biospore=1 }, outputs = { cellmateria=1}, time = 7.0},
{inputs = { blobbushjelly=1 }, outputs = { fumadnessresource=1,cellmateria=1}, time = 7.0},
{inputs = { brain=1 }, outputs = { fumadnessresource=1,cellmateria=2}, time = 7.0},
{inputs = { inferiorbrain=1 }, outputs = { fumadnessresource=1,cellmateria=1}, time = 7.0},
{inputs = { bone=10 }, outputs = { bonemealmaterial=50}, time = 7.0},
{inputs = { crunchychick=1 }, outputs = { fumadnessresource=1,bonemealmaterial=10,alienmeat=1}, time = 5.0},
{inputs = { meatpickle=1 }, outputs = { fumadnessresource=1,alienmeat=1}, time = 2.0}
}

function init()
    self.timer = 1
    self.mintick = 1
    self.crafting = false
    self.output = {}
    self.setval = 1
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
	    animator.playSound("bodydown")
        end
        if not self.crafting and self.timer <= 0 then --make sure we didn't just finish crafting
            if not startCrafting(getValidRecipes(getInputContents())) then 
              self.timer = self.mintick --set timeout if there were no recipes
              animator.stopAllSounds("cutting")
            end 
        end
    else
      if self.crafting then
	    --play sound effect randomly for grossness
	    if self.setval == 1 then
	        self.setval = 0 
		animator.playSound("cutting")
	    end 
      end
      
    end
end

function startCrafting(result)
    
    if next(result) == nil then return false
    else _,result = next(result)
        for k,v in pairs(result.inputs) do
            if not world.containerConsume(entity.id(), {item = k , count = v}) then return false end
            self.setval = 1 
            animator.playSound("bodydown")
            animator.stopAllSounds("cutting")
        end

        self.crafting = true
        self.timer = result.time
        self.output = result.outputs
        animator.setAnimationState("samplingarrayanim", "working")
        return true
    end
end

function uninit()
animator.stopAllSounds("cutting")
end

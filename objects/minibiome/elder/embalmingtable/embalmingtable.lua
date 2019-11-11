local recipes =
{
--combos
{inputs = { wrappedbody=1,elderrelic2=1 }, outputs = { inferiorbrain=1,fuscienceresource=520,bone=8,leather=1,alienmeat=4,faceskin=1,rawribmeat=2,liquidelderfluid=120  }, time = 14.0},
{inputs = { wrappedbody=1,elderrelic10=1 }, outputs = { inferiorbrain=1,fumadnessresource=520,bone=8,leather=1,alienmeat=12,rawribmeat=2,liquidelderfluid=80  }, time = 14.0},
{inputs = { wrappedbodyputrid=1,elderrelic2=1 }, outputs = { inferiorbrain=1,fuscienceresource=520,bone=8,leather=1,alienmeat=4,faceskin=1,rawribmeat=2,liquidelderfluid=120  }, time = 14.0},
{inputs = { wrappedbodyputrid=1,elderrelic10=1 }, outputs = { inferiorbrain=1,fumadnessresource=520,bone=8,leather=1,alienmeat=12,rawribmeat=2,liquidelderfluid=80  }, time = 14.0},

--flesh dissection
{inputs = { fuflesh=1 }, outputs = { leather=3,faceskin=1,rawribmeat=2,bone=24,alienmeat=4,fufemur=2,futooth=20}, time = 6.0},
{inputs = { fufleshalien=1 }, outputs = { leather=3,cellmaterial=4,cellmateria=4,rawribmeat=2,bone=24,fufemur=2,futooth=20,gene_void=1}, time = 6.0},

--heart dissection
{inputs = { fuheartalien=1 }, outputs = { liquidalienjuice = 5,gene_muscle=2,fleshstrand=5}, time = 6.0},
{inputs = { fuheart=1 }, outputs = { liquidalienjuice = 5,gene_muscle=1,fleshstrand=3}, time = 6.0},

--tooth
{inputs = { futooth=20 }, outputs = { bone = 1}, time = 1.0},


--femur
{inputs = { fufemur=1 }, outputs = { bone = 5,gene_skeletal=2}, time = 6.0},

--hair
{inputs = { fuhair=1 }, outputs = { fuscienceresource = 5 }, time = 6.0},

--brains
{inputs = { fubrain=1 }, outputs = { inferiorbrain=1,fuscienceresource=5}, time = 6.0},
{inputs = { fubrain=1,methanol=1 }, outputs = { brain=1,fuscienceresource=10,fumadnessresource=15}, time = 6.0},
{inputs = { fubrain=1,methanol=1,liquidhealing=5 }, outputs = { brainpeerless=1,fuscienceresource=25,fumadnessresource=45}, time = 6.0},

--cadavers
{inputs = { cadaver=1 }, outputs = { fuflesh=1, fuhair=1, fubrain=1, fuscienceresource=120, fumadnessresource=30,fleshstrand=4,liquidblood = 40,}, time = 8.0},
{inputs = { cadaverrotting=1 }, outputs = { fuflesh=1, fuhair=1, fubrain=1,fuscienceresource=70,fleshstrand=1,liquidpoison = 20,}, time = 8.0},
{inputs = { cadaverbirb=1 }, outputs = { fuflesh=1, fuhair=1, fubrain=1, blooddiamond=1, goldbar=2, fuscienceresource=90,fleshstrand=3 }, time = 8.0},
{inputs = { cadaveralien=1 }, outputs = { fufleshalien=1,fubrain=1,fuheartalien=1,fuscienceresource=120, fumadnessresource=30,fleshstrand=6,liquidalienjuice = 40, }, time = 8.0},

--wrapped bodies
{inputs = { wrappedbody=1 }, outputs = { cadaver=1,bandage=12,fuscienceresource=40,fumadnessresource=30}, time = 5.0},
{inputs = { wrappedbodyputrid=1 }, outputs = { cadaverrotting = 1,fumadnessresource=60,bandage=12 }, time = 5.0},
{inputs = { wrappedbodyalien=1 }, outputs = { cadaveralien = 1,fumadnessresource=80,mutaviskbandage=12 }, time = 5.0},
{inputs = { wrappedbodybirb=1 }, outputs = { cadaverbirb =1,fuscienceresource=50,fuhoneysilkbandage=12}, time = 5.0},

--miscellaneous
{inputs = { greghead=1 }, outputs = { fumadnessresource=4,inferiorbrain=1,bone=4,slew2=3}, time = 9.0},
{inputs = { severedheadplatter=1 }, outputs = { fumadnessresource=1,inferiorbrain=1,bone=4,slew2=3}, time = 9.0},
{inputs = { faceskin=1 }, outputs = { fumadnessresource=1,liquidblood=1, slew2=1}, time = 7.0},
{inputs = { leather=1 }, outputs = { slew2=1}, time = 7.0},
{inputs = { hardenedcarapace=1 }, outputs = { slew2=1}, time = 7.0},
{inputs = { agaranichor=1 }, outputs = { fuscienceresource=5}, time = 7.0},
{inputs = { biospore=1 }, outputs = { cellmateria=1}, time = 7.0},
{inputs = { blobbushjelly=1 }, outputs = { fumadnessresource=1,cellmateria=1}, time = 7.0},
{inputs = { brain=1 }, outputs = { fumadnessresource=2,cellmateria=2}, time = 7.0},
{inputs = { inferiorbrain=1 }, outputs = { fumadnessresource=1,cellmateria=1}, time = 7.0},
{inputs = { bone=10 }, outputs = { bonemealmaterial=50}, time = 7.0},
{inputs = { crunchychick=1 }, outputs = { fumadnessresource=3,bonemealmaterial=10,alienmeat=1}, time = 5.0},
{inputs = { meatpickle=1 }, outputs = { fumadnessresource=2,alienmeat=1}, time = 2.0},
{inputs = { milk=1,normaldrone=1 }, outputs = { sourmilkandbees=1}, time = 2.0}
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

require "/scripts/util.lua"

function init()
    self.tools = {
        wiretoolSlot = "wiretool",
        painttoolSlot = "painttool",
        inspectiontoolSlot = "inspectiontool"
    }

    -- FR compatibility (uses racial manipulator as base manipulator)
    _,self.racial = pcall(function (f) return root.assetJson("/frackinraces.config").manipulators end)

    resetSlots()
    resetSpinners()
    setSpinnersEnabled()
end

function update(dt)
    resetSlots()
end

function swapMM(name)
    local mm = player.essentialItem("beamaxe")
    local swapItem = player.swapSlotItem()

    if not swapItem and mm.name == origTool("beamaxe") then return end

    -- Reset stats for picked up item
    mm.parameters.blockRadius = getMaxSize(mm)
    mm.parameters.altBlockRadius = 1
    --mm.parameters.harvestLevel = 99
    if mm.parameters.upgrades and contains(mm.parameters.upgrades, "liquidcollection") then
        mm.parameters.canCollectLiquid = true
    end
    if swapItem and root.itemType(swapItem.name) == "beamminingtool" then

        -- MMs get wiremode and paintmode for free if the previous MM had it (but not liquid collection)
        swapItem.parameters.upgrades = swapItem.parameters.upgrades or {}
        if contains(mm.parameters.upgrades or {}, "wiremode")
            and not contains(swapItem.parameters.upgrades, "wiremode") then
            table.insert(swapItem.parameters.upgrades, "wiremode")
        end
        if contains(mm.parameters.upgrades or {}, "paintmode")
            and not contains(swapItem.parameters.upgrades, "paintmode") then
            table.insert(swapItem.parameters.upgrades, "paintmode")
        end

        -- give new MMs the liquid collection upgrade if they have liquid collection enabled by default
        if root.itemConfig(swapItem).config.canCollectLiquid and not contains(swapItem.parameters.upgrades or {}, "liquidcollection") then
            swapItem.parameters.upgrades = swapItem.parameters.upgrades or {}
            table.insert(swapItem.parameters.upgrades, "liquidcollection")
        end

        if mm.name == origTool("beamaxe") then
            swapItem.parameters.originalMM = mm

            player.setSwapSlotItem(nil)
        else
            swapItem.parameters.originalMM = mm.parameters.originalMM or origTool("beamaxe")
            mm.parameters.originalMM = nil -- stops spam of this data everywhere
            player.setSwapSlotItem(mm)
        end
        player.giveEssentialItem("beamaxe", swapItem)
    elseif not swapItem then
        player.setSwapSlotItem(mm)
        player.giveEssentialItem("beamaxe", mm.parameters.originalMM or origTool("beamaxe"))
    end

    resetSpinners()
    setSpinnersEnabled()
end

function swapTool(name)
    local tool = self.tools[name]

    if not player.swapSlotItem() and toolMatch(tool) then return end

    local upgrade = name == "wiretoolSlot" and "wiremode" or "paintmode"
    if name == "inspectiontoolSlot" then upgrade = "nope" end

    local mm = player.essentialItem("beamaxe")

    if (name == "inspectiontoolSlot" and (player.essentialItem("inspectiontool") or {}).name ~= "inspectionmode")
        or (mm.parameters and mm.parameters.upgrades and contains(mm.parameters.upgrades, upgrade)) then
        local swapItem = player.swapSlotItem()
        if toolMatch(tool) then
            player.setSwapSlotItem(nil)
        else
            player.setSwapSlotItem(player.essentialItem(tool))
        end
        if not swapItem then
            widget.setItemSlotItem(name, origTool(tool))
            player.giveEssentialItem(tool, origTool(tool))
        else
            player.giveEssentialItem(tool, swapItem)
            widget.setItemSlotItem(name, swapItem)
        end
        sb.logInfo(sb.print(swapItem))
    end

    resetSpinners()
    setSpinnersEnabled()
end

function origTool(slot)
    if slot == "wiretool" or slot == "painttool" then
        return slot
    elseif slot == "inspectiontool" then
        return "scanmode"
    elseif slot == "beamaxe" then
        return getBaseManip()
    end
end

function toolMatch(slot)
    local item = player.essentialItem(slot)
    if not item then return nil end
    local tool = item.name
    if tool == slot then return slot
    elseif slot == "inspectiontool" and tool == "scanmode" then return "scanmode"
    end

    return nil
end

function getBaseManip()
    if self.racial and self.racial[player.species()] then
        return self.racial[player.species()].item or "beamaxe"
    end
    return "beamaxe"
end

function resetSlots()
    widget.setItemSlotItem("beamaxeSlot", player.essentialItem("beamaxe"))
    widget.setItemSlotItem("wiretoolSlot", player.essentialItem("wiretool"))
    widget.setItemSlotItem("painttoolSlot", player.essentialItem("painttool"))
    widget.setItemSlotItem("inspectiontoolSlot", player.essentialItem("inspectiontool"))
end

function resetSpinners()
    local mm = player.essentialItem("beamaxe")
    widget.setText("sizeSpinnerLB", mm.parameters.blockRadius or root.itemConfig(mm).config.blockRadius)
    widget.setText("altSizeSpinnerLB", mm.parameters.altBlockRadius or root.itemConfig(mm).config.altBlockRadius)

    widget.setButtonEnabled("collectLiquidsCheckbox", contains(mm.parameters.upgrades or {}, "liquidcollection"))
    widget.setChecked("collectLiquidsCheckbox", getStat(mm, "canCollectLiquid"))

    local paint = player.essentialItem("painttool")
    if paint and paint.name == "painttool" then
        widget.setText("paintSizeSpinnerLB", getStat(paint, "blockRadius"))
        widget.setText("altPaintSizeSpinnerLB", getStat(paint, "altBlockRadius"))
    else
        widget.setText("paintSizeSpinnerLB", "0")
        widget.setText("altPaintSizeSpinnerLB", "0")
    end
end

function setSpinnersEnabled()
    local mm = player.essentialItem("beamaxe")
    widget.setButtonEnabled("sizeSpinner.up", getStat(mm, "blockRadius") < getMaxSize(mm))
    widget.setButtonEnabled("altSizeSpinner.up", getStat(mm, "altBlockRadius") < getMaxSize(mm))
    widget.setButtonEnabled("sizeSpinner.down", getStat(mm, "blockRadius") > 1)
    widget.setButtonEnabled("altSizeSpinner.down", getStat(mm, "altBlockRadius") > 1)

    --widget.setChecked("collectBlocksCheckbox", getStat(mm, "harvestLevel") == 99)

    local paint = player.essentialItem("painttool")
    if not paint or paint.name ~= "painttool" then
        widget.setFontColor("paintSizeLabel", "darkgray")
        widget.setFontColor("paintSizeSpinnerLB", "darkgray")
        widget.setFontColor("altPaintSizeLabel", "darkgray")
        widget.setFontColor("altPaintSizeSpinnerLB", "darkgray")
        widget.setButtonEnabled("paintSizeSpinner.up", false)
        widget.setButtonEnabled("paintSizeSpinner.down", false)
        widget.setButtonEnabled("altPaintSizeSpinner.up", false)
        widget.setButtonEnabled("altPaintSizeSpinner.down", false)
    else
        widget.setFontColor("paintSizeLabel", "green")
        widget.setFontColor("paintSizeSpinnerLB", "green")
        widget.setFontColor("altPaintSizeLabel", "green")
        widget.setFontColor("altPaintSizeSpinnerLB", "green")
        widget.setButtonEnabled("paintSizeSpinner.up", getStat(paint, "blockRadius") < getMaxSize(mm) + 1)
        widget.setButtonEnabled("paintSizeSpinner.down", getStat(paint, "blockRadius") > 1)
        widget.setButtonEnabled("altPaintSizeSpinner.up", getStat(paint, "altBlockRadius") < getMaxSize(mm) + 1)
        widget.setButtonEnabled("altPaintSizeSpinner.down", getStat(paint, "altBlockRadius") > 1)
    end
end

function getMaxSize(mm)
    local maxSize = root.itemConfig(mm).config.blockRadius

    local upgrades = {}
    for _,name in pairs(mm.parameters.upgrades or {}) do
        upgrades[name] = true
    end
    local i = 0
    while upgrades["size"..(i + 1)] do
        i = i + 1
    end

    return maxSize + i
end

function getStat(item, stat)
    if item.parameters[stat] ~= nil then
        return item.parameters[stat]
    else
        return root.itemConfig(item).config[stat]
    end
end

sizeSpinner = {}
function sizeSpinner.up()
    local mm = player.essentialItem("beamaxe")
    local maxSize = getMaxSize(mm)
    if getStat(mm, "blockRadius") < maxSize then
        mm.parameters.blockRadius = getStat(mm, "blockRadius") + 1
        player.giveEssentialItem("beamaxe", mm)
        resetSpinners()
        setSpinnersEnabled()
    end
end
function sizeSpinner.down()
    local mm = player.essentialItem("beamaxe")
    if getStat(mm, "blockRadius") > 1 then
        mm.parameters.blockRadius = getStat(mm, "blockRadius") - 1
        player.giveEssentialItem("beamaxe", mm)
        resetSpinners()
        setSpinnersEnabled()
    end
end

altSizeSpinner = {}
function altSizeSpinner.up()
    local mm = player.essentialItem("beamaxe")
    local maxSize = getMaxSize(mm)
    if getStat(mm, "altBlockRadius") < maxSize then
        mm.parameters.altBlockRadius = getStat(mm, "altBlockRadius") + 1
        player.giveEssentialItem("beamaxe", mm)
        resetSpinners()
        setSpinnersEnabled()
    end
end
function altSizeSpinner.down()
    local mm = player.essentialItem("beamaxe")
    if getStat(mm, "altBlockRadius") > 1 then
        mm.parameters.altBlockRadius = getStat(mm, "altBlockRadius") - 1
        player.giveEssentialItem("beamaxe", mm)
        resetSpinners()
        setSpinnersEnabled()
    end
end

paintSizeSpinner = {}
function paintSizeSpinner.up()
    local paint = player.essentialItem("painttool")
    if not paint or root.itemType(paint.name) ~= "paintingbeamtool" then return end
    local maxSize = getMaxSize(player.essentialItem("beamaxe")) + 1
    if getStat(paint, "blockRadius") < maxSize then
        paint.parameters.blockRadius = getStat(paint, "blockRadius") + 1
        player.giveEssentialItem("painttool", paint)
        resetSpinners()
        setSpinnersEnabled()
    end
end
function paintSizeSpinner.down()
    local paint = player.essentialItem("painttool")
    sb.logInfo(sb.print(root.itemType(paint.name)))
    if not paint or root.itemType(paint.name) ~= "paintingbeamtool" then return end
    if getStat(paint, "blockRadius") > 1 then
        paint.parameters.blockRadius = getStat(paint, "blockRadius") - 1
        player.giveEssentialItem("painttool", paint)
        resetSpinners()
        setSpinnersEnabled()
    end
end

altPaintSizeSpinner = {}
function altPaintSizeSpinner.up()
    local paint = player.essentialItem("painttool")
    if not paint or root.itemType(paint.name) ~= "paintingbeamtool" then return end
    local maxSize = getMaxSize(player.essentialItem("beamaxe")) + 1
    if getStat(paint, "altBlockRadius") < maxSize then
        paint.parameters.altBlockRadius = getStat(paint, "altBlockRadius") + 1
        player.giveEssentialItem("painttool", paint)
        resetSpinners()
        setSpinnersEnabled()
    end
end
function altPaintSizeSpinner.down()
    local paint = player.essentialItem("painttool")
    if not paint or root.itemType(paint.name) ~= "paintingbeamtool" then return end
    if getStat(paint, "altBlockRadius") > 1 then
        paint.parameters.altBlockRadius = getStat(paint, "altBlockRadius") - 1
        player.giveEssentialItem("painttool", paint)
        resetSpinners()
        setSpinnersEnabled()
    end
end

--[[function blockCheckbox(name)
    local checked = widget.getChecked(name)
    local mm = player.essentialItem("beamaxe")
    mm.parameters.tileDamage = checked and 99 or -99
    player.giveEssentialItem("beamaxe", mm)
end]]
function liquidsCheckbox(name)
    local checked = widget.getChecked(name)
    local mm = player.essentialItem("beamaxe")
    if mm.parameters.upgrades and contains(mm.parameters.upgrades, "liquidcollection") then
        mm.parameters.canCollectLiquid = checked
        player.giveEssentialItem("beamaxe", mm)
    end
end

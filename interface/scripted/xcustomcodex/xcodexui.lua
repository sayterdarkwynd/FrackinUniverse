-- Custom Codex UI by Xan the Dragon // Eti the Spirit [RBX 18406183]
-- Proposed by Sayter, approved of by Xan
-- And then made by Xan


-- Because starbound needs to up their game, like damn





-- To reference any ScrollArea children widgets in Lua scripts (widget.* table) use the following format: <ScrollArea name>.<Children widget name>.

local print, warn, error, assertwarn, assert, tostring; -- Specify these as locals
require("/scripts/xcore_customcodex/LoggingOverride.lua") -- tl;dr I can use print, warn, error, assert, and assertwarn

---------------------------
------ TEMPLATE DATA ------
---------------------------

-- A template for one of the buttons displayed in the list of codex entries.
local TEMPLATE_CODEX_ENTRY_BUTTON = {
	type = "button",
	caption = "",
	textAlign = "center",
	base = "/interface/scripted/xcustomcodex/codexbutton.png",
	hover = "/interface/scripted/xcustomcodex/codexbuttonhover.png",
	pressed = "/interface/scripted/xcustomcodex/codexbuttonhover.png",
	callback = "ListButtonClicked"
}

local TEMPLATE_CODEX_RACE_CATEGORY = {
	type = "list",
	callback = "RaceButtonClicked",
	schema = {
		selectedBG = "/interface/scripted/xcustomcodex/racebuttonhover.png",
		unselectedBG = "/interface/scripted/xcustomcodex/racebutton.png",
		spacing = {0, 0},
		memberSize = {24, 24},
		listTemplate = {
			constBG = {
				type = "image",
				file = "/interface/scripted/xcustomcodex/racebutton.png"
			},
			raceIcon = {
				type = "image",
				file = "",
				zlevel = 1
			},
			raceButton = {
				type = "button",
				caption = "",
				textAlign = "center",
				base = "/interface/scripted/xcustomcodex/racebutton.png",
				hover = "/interface/scripted/xcustomcodex/racebuttonhover.png",
				pressed = "/interface/scripted/xcustomcodex/racebuttonhover.png",
				callback = "null"
			},
			buttonLabel = {
				type = "label",
				value = "",
				hAnchor = "mid",
				vAnchor = "mid",
				position = {12, 12},
				zLevel = 2
			}
		}
	}
}

-----------------------
------ CORE DATA ------
-----------------------

local CodexButtonBindings = {}
local ExistingCategoryButtons = {}
local CurrentPage = 1
local CurrentCodex = nil
local NextButtonEnabled = false
local PrevButtonEnabled = false
local IsFirstTimeOpening = true

------------------------------
------ HELPER FUNCTIONS ------
------------------------------

local function UpdateBasedOnPage(pages, currentPage)
	local numPages = #pages
	local nextEnabled = currentPage < numPages
	local prevEnabled = currentPage > 1
	
	widget.setButtonEnabled("nextButton", nextEnabled)
	widget.setButtonEnabled("prevButton", prevEnabled)
	widget.setFontColor("nextButton", nextEnabled and "#FFFFFF" or "#666666")
	widget.setFontColor("prevButton", prevEnabled and "#FFFFFF" or "#666666")
	
	NextButtonEnabled = nextEnabled
	PrevButtonEnabled = prevEnabled
	
	widget.setText("currentPageLabel", "Page " .. currentPage .. " of " .. numPages)
	
	local pageText = pages[currentPage]
	widget.setText("codexText.textElement", pageText)
end

local function GetNameAbbreviation(name, existingAbbreviations, startSub, maxLen)
	local maxLen = maxLen or 4
	local startSub = startSub or 1
	local abv = name:sub(1, startSub)
	for i = 2, #name do
		-- Yes, #name works on top of name:len() or whatever.
		local chr = name:sub(i, i)
		if chr:upper() == chr and chr ~= " " then
			abv = abv .. chr
		end
		if #abv > maxLen then
			break
		end
	end
	
	for index, abbreviation in ipairs(existingAbbreviations) do
		if abv == abbreviation then
			return GetNameAbbreviation(name, existingAbbreviations, startSub + 1)
		end
	end
	return abv
end

-------------------------------
------ PRIMARY FUNCTIONS ------
-------------------------------


-- Creates a button on the left-most list to view this codex
local function CreateButtonToReadCodex(codexData, codexFileInfo, index)
	local buttonName = "cdx_" .. codexData.id
	
	local button = TEMPLATE_CODEX_ENTRY_BUTTON
	button.caption = codexData.title or "ERR_NO_TITLE"
	button.position = {0, index * -22}
	CodexButtonBindings[buttonName] = codexData
	
	local codexFilePath = codexFileInfo[2]
	if codexData.icon:sub(1, 1) ~= "/" then
		-- This is a relative filepath to the same folder.
		-- Translate the icon parameter to use an absolute path instead.
		CodexButtonBindings[buttonName].icon = codexFilePath .. CodexButtonBindings[buttonName].icon
	end
	
	widget.addChild("codexList", button, buttonName)	
	--print("Button " .. buttonName .. " added to codex list children.")
end

local function OpenCodex(codexData, page)
	CurrentPage = page or 1
	widget.setText("codexTitle", codexData.title)
	UpdateBasedOnPage(codexData.contentPages, CurrentPage)
	CurrentCodex = codexData
end

local function PopulateCodexEntriesForCategory(categoryData)
	widget.removeAllChildren("codexList")
	
	local targetCategory = categoryData[1]
	local speciesName = categoryData[2]
	
	widget.setText("codexListRace", "Selected Race / Category: " .. speciesName)
	
	local knownCodexEntries = player.getProperty("xcodex.knownCodexEntries") or {}
	local posIndex = 0
	for index = 1, #knownCodexEntries do
		local codexInfo = knownCodexEntries[index]
		-- {codexRawName, codexJsonPath}
		
		-- TEST: Does this even exist?
		local rawCodexData = nil
		local exists = pcall(function ()
			rawCodexData = root.assetJson(codexInfo[2] .. codexInfo[1] .. ".codex")
		end) -- If this errors the pcall will return false.
		
		if exists then
			local category = rawCodexData.species or ""
			if category == targetCategory then
				--print("Creating button for codex " .. tostring(codexInfo[1]))
				
				if rawCodexData.longContentPages ~= nil and #rawCodexData.longContentPages > 0 then
					rawCodexData.contentPages = rawCodexData.longContentPages
				end
				CreateButtonToReadCodex(rawCodexData, codexInfo, posIndex)
				
				posIndex = posIndex + 1
			end
		end
	end
	
	if positionalIndex == 1 and widget.getText("codexText.textElement") == "" then
		widget.setText("codexTitle", "No Known Codex Entries :(")
	end
end

local function PopulateCategories()
	local knownCodexEntries = player.getProperty("xcodex.knownCodexEntries") or {}
	
	-- I want to order the buttons alphabetically.
	local buttonInfo = {}
	local existingAbbreviations = {}
	
	local listTemplate = TEMPLATE_CODEX_RACE_CATEGORY
	widget.addChild("racialCategoryList", listTemplate, "racelist")
	
	for index = 1, #knownCodexEntries do
		local codexInfo = knownCodexEntries[index]
		-- {codexRawName, codexJsonPath}
		
		-- TEST: Does this even exist?
		local rawCodexData = nil
		local exists = pcall(function ()
			rawCodexData = root.assetJson(codexInfo[2] .. codexInfo[1] .. ".codex")
		end) -- If this errors the pcall will return false.
		
		if exists then
			local displayName = ""
			local category = rawCodexData.species or ""
			local actualRaceName = "Ambiguous"
			local speciesData
			
			if category ~= "" then
				local speciesDataExists = pcall(function ()
					speciesData = root.assetJson("/species/" .. category .. ".species")
				end)
				if speciesDataExists then
					local ct = speciesData.charCreationTooltip
					if ct and ct.title and #ct.title >= 1 then
						displayName = GetNameAbbreviation(ct.title, existingAbbreviations)
						table.insert(existingAbbreviations, displayName)
						actualRaceName = ct.title
					end
				end
			end
			
			local buttonName = "race-" .. actualRaceName
			local i = 1
			if not ExistingCategoryButtons[buttonName] then
				local newElement = widget.addListItem("racialCategoryList.racelist")
				--print(tostring(newElement))
				
				if speciesData ~= nil then
					local genderTable
					for index, tbl in pairs(speciesData.genders) do genderTable = tbl break end -- This is a hacky method of getting the first element of a table with non-integer keys.
					if genderTable and genderTable.characterImage then
						--print("Set button icon to", genderTable.characterImage)
						widget.setImage("racialCategoryList.racelist." .. tostring(newElement) .. ".raceIcon", genderTable.characterImage)
						widget.setButtonImages("racialCategoryList.racelist." .. tostring(newElement) .. ".raceButton", 
							{
								base = genderTable.characterImage,
								hover = genderTable.characterImage .. "?brightness=30",
								hover = genderTable.characterImage .. "?brightness=30",
								disabled = ""
							}
						)
					end
				else
					--print("Could not set button icon -- race doesn't exist (this is the ambiguous table) or the race was unable to resolve an appropriate icon.")
					widget.setText("racialCategoryList.racelist." .. tostring(newElement) .. ".buttonLabel", "*")
				end
				
				widget.setData("racialCategoryList.racelist." .. tostring(newElement), {buttonName})
			
				ExistingCategoryButtons[buttonName] = {category, actualRaceName}
			end
		end
	end
end

-----------------------
------ CALLBACKS ------
-----------------------

-- Run when a button for the codex list is clicked.
function ListButtonClicked(widgetName, widgetData)
	local data = CodexButtonBindings[widgetName]
	if data then OpenCodex(data) end
end

function RaceButtonClicked(widgetName, widgetData)
	-- widgetName is the racedata, the list
	local itemId = widget.getListSelected("racialCategoryList.racelist")
	local raceButtonName = widget.getData("racialCategoryList.racelist." .. tostring(itemId))[1]
	local data = ExistingCategoryButtons[raceButtonName]
	if data then PopulateCodexEntriesForCategory(data) end
end

-- Run when the "Previous Page" button is clicked.
function PreviousButtonClicked(widgetName, widgetData)
	if not PrevButtonEnabled then return end
	CurrentPage = CurrentPage - 1
	UpdateBasedOnPage(CurrentCodex.contentPages, CurrentPage)
end

-- Run when the "Next Page" button is clicked.
function NextButtonClicked(widgetName, widgetData)
	if not NextButtonEnabled then return end
	CurrentPage = CurrentPage + 1
	UpdateBasedOnPage(CurrentCodex.contentPages, CurrentPage)
end

------------------------------
------ LOADER FUNCTIONS ------
------------------------------

-- Added by InitUtility. Runs *after* init but *before* the first update() call.
function postinit()
	print, warn, error, assertwarn, assert, tostring = CreateLoggingOverride("[High-Fidelity Codex GUI]")
	
	--local subtitle = "The best reading experience you'll ever get"
	--local chance = math.random()
	--if chance < 0.005 and not IsFirstTimeOpening then
	--	subtitle = subtitle .. " - From Protostar!"
		-- https://youtu.be/ScEliEh2_Xo?t=12
	--end
	IsFirstTimeOpening = false
	
	-- Set UI to be completely disabled.
	widget.setText("windowSubtitle", subtitle)
	widget.setButtonEnabled("nextButton", false)
	widget.setButtonEnabled("prevButton", false)
	widget.setFontColor("nextButton", "#666666")
	widget.setFontColor("prevButton", "#666666")
	
	PopulateCategories()
end


-- Yes, this goes down here. Don't move it or you will break it.
require("/scripts/xcore_customcodex/InitializationUtility.lua")

-- THIS IS THE FRACKIN RACES ONE
require "/scripts/util.lua"

function init()
	self.data = root.assetJson("/interface/scripted/statWindow/statWindow.config")
	self.elements = self.data.elements
	self.statuses = self.data.statuses
	self.extraOpen = false
	
	widget.setText("characterName", "^blue;"..world.entityName(player.id()))
	
	local playerRace = status.statusProperty("fr_race")
	local recognized = false
	for _,race in ipairs(self.data.races) do
		if race == playerRace then
			recognized = true
			break
		end
	end
	
	if not status.statusProperty("fr_enabled") then recognized = false end

	if recognized then
		widget.setImage("characterSuit", "/interface/scripted/techupgrade/suits/"..playerRace.."-"..player.gender()..".png")
		--widget.setText("racialLabel", "Racial traits - "..playerRace) --Moved into populateRacialDescription to get the friendly-text name.
		widget.setVisible("racialDesc", true)
		widget.setVisible("offline", false)
		
		populateRacialDescription(playerRace)
	else
		widget.setText("racialLabel", "ERROR - UNRECOGNIZED SPECIES")
	end
end

function update()
	for _, element in ipairs(self.elements) do
		widget.setText(element.."Resist", math.floor(status.stat(element.."Resistance")*100+0.5).."%")
	end

	widget.clearListItems("immunitiesList.textList")
	for thing,stuff in pairs(self.statuses) do
		local skipping = false

		for _,skipped in ipairs(stuff.skip or {}) do
			if status.stat(skipped) >= 1 then
				skipping = true
				break
			end
		end

		if not skipping then
			if status.stat(thing) >= 1 then
				local listItem = "immunitiesList.textList."..widget.addListItem("immunitiesList.textList")
				widget.setText(listItem..".immunity", stuff.name)
			end
		end
	end
end

function expand()
	player.interact("ScriptPane", "/interface/scripted/statWindow/extraStatsWindow.config", player.id())
end

function loreBook()
	player.interact("ScriptPane", "/interface/scripted/xcustomcodex/xcodexui.config", player.id())
end
function research()
	player.interact("ScriptPane", "/zb/researchTree/researchTree.config", player.id())
end

function mechEquip()
	player.interact("ScriptPane", "/interface/scripted/mechassembly/mechassemblygui.config", player.id())
end
function mechFuel()
	player.interact("ScriptPane", "/interface/mechfuel/mechfuel.config", player.id())
end

function techBuild()
	player.interact("ScriptPane", "/interface/scripted/techshop/techshop.config", player.id())
end
function techEquip()
	player.interact("ScriptPane", "/interface/scripted/techupgrade/techupgradegui.config", player.id())
end


function populateRacialDescription(race)
	widget.clearListItems("racialDesc.textList")
	
	local JSON = root.assetJson("/species/"..race..".species")
	--local charGenLabels = JSON.charGenTextLabels
	--local racialName = charGenLabels[#charGenLabels-1] --NOTE: In the species file there is the character generation label list. The second to last is the user-friendly display name of the race.
	--Edit: Go with the character creation tooltip title.
	local racialName = JSON.charCreationTooltip.title
	widget.setText("racialLabel", "Racial Traits - " .. racialName)
	
	local str = JSON.charCreationTooltip.description
	local strTbl = {}
	local splitters = {}
	local lists = {}
	local startFound = false
	local skipped = 0
	local skip = false
	local firstskip = false
	local char = ""
	
	str=string.gsub(str,"\r\n","\n")
	local str2=str
	while str~=string.gsub(str," \n","\n") do
		str=string.gsub(str," \n","\n")
	end
	--[[str=string.gsub(str,"    \n","\n")
	str=string.gsub(str,"  \n","\n")
	str=string.gsub(str," \n","\n")]]
	str=string.gsub(str,"\n  ","\n>")
	local wordWall={}
	local line={}
	local sentence=""
	
	for i = 1, string.len(str) do
		local c = string.sub(str, i, i)
		if c == "\n" or i==string.len(str) then
			if (i==(string.len(str))) then table.insert(line,c) end
			if util.tableSize(line) > 0 then
				local sentenceSize=0
				local word={}
				local wordTest=""
				local colorTest=""
				for i = 1, #line do
					local c2=line[i]
					if i==#line or c2==" " then
						if i==#line and not (c2==" ") then
							table.insert(word,c2)
						end
						local heightened=false
						for k = 1, #word do
							local c3 = word[k]
							if c3=="^" then
								heightened=true
								colorTest=c3
							elseif heightened and c3==";" then
								colorTest=colorTest..c3
								heightened=false
							elseif not heightened then
								wordTest=wordTest..c3
							else
								colorTest=colorTest..c3
							end
						end
						sb.logInfo("%s::%s",wordTest,colorTest)
						--sb.logInfo("%s",wordTest)
						--sb.logInfo("%s",colorTest)
						if (string.len(sentence) + string.len(wordTest)) > 60 then
							table.insert(wordWall,sentence)
							sentence=colorTest
						end
						if string.len(sentence) > 0 then sentence = sentence.." " end
						sentence=sentence..table.concat(word)
						word={}
						wordTest=""
					else
						table.insert(word,c2)
					end
				end
				
				--[[local heightened=false
				for j = 1, #line do
					local c2 =line[j]
					if c2=="^" then
						heightened=true
					elseif heightened and c2==";" then
						heightened=false
					elseif heightened then
						--ignore
					else
						
					end
				end
				local cat=table.concat(line)
				local uncat
				table.insert(wordWall,cat)]]
				table.insert(wordWall,sentence)
				sentence=""
			end
			line={}
		else
			table.insert(line,c)
		end
	end
	--sb.logInfo("%s",wordWall)
	for i = 1, #wordWall do
		local listItem = "racialDesc.textList."..widget.addListItem("racialDesc.textList")
		widget.setText(listItem..".trait", wordWall[i])
	end
	return
	--Some text editors use the windows line ending, like notepad++
	--We need to normalize this to just use the unix style ending (\n), as Windows line endings are CRLF (\r\n) and cause double-newlines.
	
	--[[for i = 1, string.len(str) do
		char = string.sub(str, i, i)
		
		if char == "\n" then
			if firstskip == true then
				skip = true
				if startFound then
					skipped = skipped + 1
					table.insert(splitters, i-skipped)
				else
					startFound = true
				end
			else
				firstskip = true
			end
		end
		
		if startFound then
			if skip then
				skip = false
			else
				table.insert(strTbl, char)
			end
		else
			skipped = skipped + 1
		end
	end
	
	str = ""
	for loc, string in ipairs(strTbl) do
		if loc == #strTbl then
			str = string.gsub(str..string, "- ", "", 1)
			table.insert(lists, str)
		else
			for _,loc2 in ipairs(splitters) do
				if loc == loc2 then
					str = string.gsub(str, "- ", "", 1)
					table.insert(lists, str)
					str = ""
				end
			end
			
			char = string
			str = string.format("%s%s", str, char) -- At this moment, I learned how important string.format truly is. Its all mightyness is able to merge % without breaking!
		end
	end]]
	
	-- using 'for i' loop because 'i/pairs' tends to fuck up the order
	--[[
	for i = 1, #lists do
		local listItem = "racialDesc.textList."..widget.addListItem("racialDesc.textList")
		widget.setText(listItem..".trait", lists[i])
	end]]
end

function upgradeEquipmentMenu()
	player.interact("ScriptPane", "/interface/scripted/fu_multiupgrade/fu_multiupgrade.config", player.id())
end
--	Author: zimberzimber

--		Instructions:
--	Link the GUI that you wish to have a typed in text (instead of a "BAM! NINE MILLION CHARACTERS IN ONE SECOND")
--	Make sure the GUI has a 'scriptDelta', and have the 'update' function in the .lua file call the 'textTyper.update' update
--	You !MUST! create a table (even an empty one) and pass it down to any function thats used in the typer
--	Should a function (button clicked, init, etc...) display text, just call 'textTyper.init' with the right parameters

--		Functions:
--	textTyper.init( textData, string, string )
--		textData	= Table that holds data required for the script to function
--		string		= The string you want printed
--		string		= The path to the sound fiel you want playing while the character is talking
--	Modifies the table into a formatted table holding a chain of strings for the updater to process
--	Use this whenever starting/changing texts

--	textTyper.update( textData, widget, sound, volume, cutoffSound )
--		textData	= Table that holds data required for the script to function
--		widget		= [Optional] The widget that should have its text updated
--		sound		= [Optional] The sound you want to play with each typed character
--		volume		= [Optional] The volume of the sound
--		cutoffSound	= [Optional] Should the sound be cut-off in the middle when typing the next character?
--	Call this whenever the text should be updated

--	textTyper.skip( textData )
--		textData	= Table that holds data required for the script to function
--		wd			= [Optional] The widget that should have its text updated
--	Instantly prints the entire text, skipping the typing part

--	textTyper.scrambling( textData )
--		textData	= Table that holds data required for the script to function
--	If you've added scrambling letters, you must call this function for them to actually scramble

--		Formats:
--	Regular formats that start with ^ and end with ; are automatically compressed
--	[(data)x]		= Inserts data from a table inside textData. For instance, [(data)questData.location] will insert whats in 'textData.questData.location'
--	[(pause)x]		= Pause the text for a short time, x being the number of 'update cycles' you want to skip text reading.
--	[(instant)x]	= Write a text instantly, x being the text
--	[(playername)]	= Writes the players name
--	[(scramble)x]	= Scrambling letters, x being the number or scrambling letters to insert
--	[(function)x]	= Call a function from the textData table, x being its location in the textData table (x = "example" , textData.example)

textTyper = {}
textTyper.allowedScrambleCharacters = "abdeghnopqsuvyzABDGHJKNOPQRSUVXY023456789_~"

function textTyper.init(textData, str, sound)
	if not textData then
		sb.logError("[ZB] textTyper.init in textTyper received no textData table, writing aborted.")
		return
	end

	textData.toWrite = {}
	textData.scrambingLetters = {}
	textData.functionCalls = {}
	textData.written = ""
	textData.textPause = 0
	textData.isFinished = false
	local textCopy = str
	local formatPause = 0
	local skippedChars = 0 -- Required for text scrambling coords

	if textData.soundPlaying then
		textTyper.stopSounds(textData)
		textData.soundPlaying = nil
	end

	if sound then
		textData.soundPlaying = sound
		pane.playSound(sound, -1, 1)
	end

	if textCopy == nil then
		textCopy = "^red;ERROR -^reset;\ntextTyper.init received a nil value in 'str'"
	elseif type(textCopy) ~= "string" then
		textCopy = "^red;ERROR -^reset;\ntextTyper.init received a non-string value in 'str'"
	end

	for i = 1, string.len(textCopy) do
		if formatPause > 0 then
			formatPause = formatPause - 1
		else
			local str = string.sub(textCopy, i, i)
			if str == "^" then
				local formatEnd = string.find(textCopy, ";", i)
				if formatEnd then
					str = string.sub(textCopy, i, formatEnd)
					skippedChars = skippedChars + string.len(str) - 1
					formatPause = formatEnd - i
				end

			elseif str == "[" then
				local bracketEnd = string.find(textCopy, "]", i)
				if bracketEnd then
					local format = string.sub(textCopy, i+1, bracketEnd-1)
					if format == "(playername)" then
						formatPause = bracketEnd - i

						local playerName = world.entityName(player.id())
						for j = 1, string.len(playerName) do
							table.insert(textData.toWrite, string.sub(playerName, j, j))
						end
						str = nil

					elseif string.find(format, "(pause)") then
						formatPause = bracketEnd - i
						str = string.sub(textCopy, i, bracketEnd)

					elseif string.find(format, "(instant)") then
						formatPause = bracketEnd - i
						str = string.sub(textCopy, i+10, bracketEnd-1)
						skippedChars = skippedChars + string.len(str) - 1

					elseif string.find(format, "(data)") then
						formatPause = bracketEnd - i

						str = string.sub(textCopy, i+7, bracketEnd-1)
						local location = textTyper.splitTableString(str)
						local data = textData

						for j = 1, #location do
							data = data[location[j]]
						end

						skippedChars = skippedChars + string.len(data) - 1

						for j = 1, string.len(data) do
							table.insert(textData.toWrite, string.sub(data, j, j))
						end

						str = nil

					elseif string.find(format, "(scramble)") then
						amount = tonumber(string.sub(textCopy, i+11, bracketEnd-1))
						table.insert(textData.scrambingLetters, #textData.toWrite + skippedChars..";"..#textData.toWrite + skippedChars + amount)

						for _ = 1, amount do
							table.insert(textData.toWrite, "#")
						end

						formatPause = bracketEnd - i
						str = nil

					elseif string.find(format, "(function)") then
						funcName = string.sub(textCopy, i+11, bracketEnd-1)
						textData.functionCalls[#textData.toWrite] = funcName

						formatPause = bracketEnd - i
						str = nil
					end
				end
			end

			if str then
				table.insert(textData.toWrite, str)
			end
		end
	end

	local removedIndexes = {}
	for i, character in ipairs(textData.toWrite) do
		if not (#removedIndexes > 0 and removedIndexes[#removedIndexes] == i+1) then
			if string.byte(character) > 127 then
				textData.toWrite[i] = utf8.char(159)
				table.insert(removedIndexes, 1, i+1)
			end
		end
	end

	for _, index in ipairs(removedIndexes) do
		table.remove(textData.toWrite, index)
	end
end

function textTyper.splitTableString(str)
	local split = {}
	local copy = str
	local temp
	local dotPos = 0

	while dotPos do
		dotPos = string.find(copy, "%.", 1)
		temp = string.sub(copy, 1, dotPos, 1)
		copy = string.gsub(copy, temp, "", 1)
		temp = string.gsub(temp, "%.", "", 1)
		table.insert(split, temp)
	end

	return split
end

function textTyper.update(textData, wd, sound, volume, cutoffSound)
	if not textData.isFinished then
		if textData.textPause and textData.textPause > 0 then
			textData.textPause = textData.textPause - 1
			return
		else
			local write = textData.toWrite[1]
			if write then

				if cutoffSound and sound then
					if type(sound) == "table" then
						for _, snd in ipairs(sound) do
							pane.stopAllSounds(snd)
						end
					else
						pane.stopAllSounds(sound)
					end
				end

				if sound then
					if type(sound) == "table" then
						pane.playSound(sound[math.random(1, #sound)], 0, (volume or 1))
					else
						pane.playSound(sound, 0, (volume or 1))
					end
				end

				local length = string.len(textData.written)
				if textData.functionCalls and textData.functionCalls[length] then
					textData[textData.functionCalls[length]]()
				end

				if string.len(write) > 1 then
					if string.sub(write, 1, 8) == "[(pause)" then
						local pause = string.gsub(write, "%D", "")
						textData.textPause = math.ceil(tonumber(pause))
						table.remove(textData.toWrite, 1)
					else
						textData.written = textData.written..write
						table.remove(textData.toWrite, 1)

						if wd then
							widget.setText(wd, textData.written)
						end
					end
				else
					textData.written = textData.written..write
					table.remove(textData.toWrite, 1)

					if wd then
						widget.setText(wd, textData.written)
					end
				end
			else
				textData.isFinished = true
				if textData.soundPlaying then
					textTyper.stopSounds(textData)
					textData.soundPlaying = nil
				end
			end
		end
	end
end

function textTyper.skip(textData, wd)
	if not textData.isFinished then
		for i = 1, #textData.toWrite do
			local write = textData.toWrite[i]
			if string.len(write) > 1 then
				if string.sub(write, 1, 8) ~= "[(pause)" then
					textData.written = textData.written..write
				end
			else
				textData.written = textData.written..write
			end
		end

		if wd then
			widget.setText(wd, textData.written)
		end

		textData.textPause = 0
		textData.isFinished = true
	end
end

function textTyper.scrambling(textData)
	if not textData or not textData.scrambingLetters or #textData.scrambingLetters == 0 then return end

	for _, coords in ipairs(textData.scrambingLetters) do
		local textLength = string.len(textData.written)
		local coordsBreaker = string.find(coords, ";")
		local pointA = tonumber(string.sub(coords, 1, coordsBreaker-1))
		local pointB = tonumber(string.sub(coords, coordsBreaker+1, string.len(coords)))

		if textLength < pointA then return end
		if textLength < pointB then pointB = textLength end

		local preScramble = string.sub(textData.written, 1, pointA)
		local toScramble = string.sub(textData.written, pointA + 1, pointB)
		local postScramble = string.sub(textData.written, pointB + 1, textLength)

		if toScramble ~= "" then
			local replacement = ""
			for _ = 1, string.len(toScramble) do
				-- replacement = replacement..textTyper.allowedScrambleCharacters[math.random(1,#textTyper.allowedScrambleCharacters)]
				local rnd = math.random(1, string.len(textTyper.allowedScrambleCharacters))
				replacement = replacement..string.sub(textTyper.allowedScrambleCharacters, rnd, rnd)
			end

			textData.written = preScramble..replacement..postScramble
		end
	end
end

function textTyper.stopSounds(textData)
	if type(textData.soundPlaying) == "table" then
		for _, snd in ipairs(textData.soundPlaying) do
			pane.stopAllSounds(snd)
		end
	elseif textData.soundPlaying then
		pane.stopAllSounds(textData.soundPlaying)
	end
end

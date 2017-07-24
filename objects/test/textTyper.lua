--	Author: zimberzimber

--		Functions:
--	writerInit( textData, race, type )
--	  textData	= Table that holds data required for the script to function
--	  race		= String that holds a race name
--	  context	= String that holds the context of the text
--	Returns a formatted table holding a chain of strings for the updater to process
--	Use this whenever starting/changing texts

--	writerUpdate( textData, sound )
--	  textData	= Table that holds data required for the script to function
--	  sound		= String holding the path to the sound file
--	Updates the table with the new string

--		Formats:
--	Regular formats that start with ^ and end with ; are automatically compressed
--	[(tp)x]		 = Pause the text for a short time, x being the number of 'update cycles' you want to skip text reading.
--	[(instant)x] = Write a text instantly, x being the text
--	[playername] = Writes the players name

function writerInit( textData, race, type )
	if not textData then return end
	
	textData.toWrite = {} 
	textData.written = ""
	textData.textPause = 0
	local textCopy = textData[race][type]
	local formatPause = 0
	
	for i = 1, string.len(textCopy) do
		if formatPause > 0 then
			formatPause = formatPause - 1
		else
			local str = string.sub(textCopy, i, i)
			if str == "^" then
				local formatEnd = string.find(textCopy, ";", i)
				str = string.sub(textCopy, i, formatEnd)
				formatPause = formatEnd - i
				
			elseif str == "[" then
				local bracketEnd = string.find(textCopy, "]", i)
				if bracketEnd then
					local format = string.sub(textCopy, i+1, bracketEnd-1)
					if format == "playername" then
						local playerName = world.entityName(player.id())
						for j = 1, string.len(playerName) do
							table.insert(textData.toWrite, string.sub(playerName, j, j))
						end
						formatPause = bracketEnd - i
						str = nil
						
					elseif string.find(format, "(tp)") then
						str = string.sub(textCopy, i, bracketEnd)
						formatPause = bracketEnd - i
						
					elseif string.find(format, "(instant)") then
						local instantText = string.sub(textCopy, i+10, bracketEnd-1)
						str = instantText
						formatPause = bracketEnd - i
					end
				end
			end
			
			if str then
				table.insert(textData.toWrite, str)
			end
		end
	end
end

function writerUpdate(textData, sound, volume)
	if textData.textPause and textData.textPause > 0 then
		textData.textPause = textData.textPause - 1
		return
	else
		local write = textData.toWrite[1]
		if write then
			if string.len(write) > 1 then
				if string.sub(write, 1, 5) == "[(tp)" then
					local pause = string.gsub(write, "%D", "")
					textData.textPause = math.ceil(tonumber(pause))
					table.remove(textData.toWrite, 1)
				else
					textData.written = textData.written..write
					table.remove(textData.toWrite, 1)
					
					if sound then
						pane.playSound(sound, 0, math.random(7,10)/10)
					end
				end
			else
				textData.written = textData.written..write
				table.remove(textData.toWrite, 1)
				
				if sound then
					if volume then
						pane.playSound(sound, 0, volume)
					else
						pane.playSound(sound, 0, 1)
					end
				end
			end
		end
	end
end

SLASH_MAGNIFY1 = '/magnify'
SlashCmdList['MAGNIFY'] = function(msg)
	local args = {}
	local i = 1
	for arg in string.gfind(string.lower(msg), '%S+') do
		args[i] = arg
		i = i + 1
	end

	if not args[1] then
		DEFAULT_CHAT_FRAME:AddMessage('|cffffdc7aMagnify |cffffffffoptions')
		DEFAULT_CHAT_FRAME:AddMessage(' ')
        DEFAULT_CHAT_FRAME:AddMessage('|cffcecece/magnify |cffffffffarrow flash - toggle player indicator arrow flash')
		DEFAULT_CHAT_FRAME:AddMessage('|cffcecece/magnify |cffffffffarrow scale [number] - set player arrow scale')
		DEFAULT_CHAT_FRAME:AddMessage('|cffcecece/magnify |cffffffffzoom reset - toggle whether to remember zoom level upon closing the map')
		DEFAULT_CHAT_FRAME:AddMessage('|cffcecece/magnify |cffffffffzoom max [number] - set max world map zoom')
	elseif args[1] == 'arrow' then
		if args[2] == 'flash' then
			Magnify_Settings['arrow_flash'] = not Magnify_Settings['arrow_flash']

			DEFAULT_CHAT_FRAME:AddMessage('|cffffdc7aMagnify|cffffffff: World map player arrow flash ' .. (Magnify_Settings['arrow_flash'] and '|cff4dd23denabled' or '|cffce2323disabled') .. '|cffffffff.')
        elseif args[2] == 'scale' then
            if args[3] then
                Magnify_Settings['arrow_scale'] = tonumber(args[3])

                DEFAULT_CHAT_FRAME:AddMessage('|cffffdc7aMagnify|cffffffff: World map player arrow scale set to |cff3083dd' .. args[3] .. '|cffffffff. This change will be applied after you reload your interface.')
            end
        end
    elseif args[1] == 'zoom' then
		if args[2] == 'reset' then
			Magnify_Settings['zoom_reset'] = not Magnify_Settings['zoom_reset']

			DEFAULT_CHAT_FRAME:AddMessage('|cffffdc7aMagnify|cffffffff: World map zoom level will be |cff3083dd' .. (Magnify_Settings['zoom_reset'] and 'reset' or 'saved') .. ' |cffffffffafter closing the map.')
		elseif args[2] == 'max' then
			if args[3] then
				Magnify_Settings['max_zoom'] = tonumber(args[3])

				DEFAULT_CHAT_FRAME:AddMessage('|cffffdc7aMagnify|cffffffff: Max world map zoom level set to |cff3083dd' .. args[3] .. '|cffffffff. This change will be applied after you reload your interface.')
			end
		end
	end
end
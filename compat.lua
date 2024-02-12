local _G = getfenv(0)

function Magnify_HandleAddons()
	-- Cartographer
	if IsAddOnLoaded('Cartographer') then
		local goToButton = _G['CartographerGoToButton']
		if goToButton then
			CartographerGoToButton:ClearAllPoints()
			CartographerGoToButton:SetPoint('TOPLEFT', WorldMapPositioningGuide, 12, -35)
		end

		local optionsButton = _G['CartographerOptionsButton']
		if optionsButton then
			CartographerOptionsButton:ClearAllPoints()
			CartographerOptionsButton:SetPoint('TOPRIGHT', WorldMapPositioningGuide, -12, -35)
		end

		local holder = _G['CartographerLookNFeelOverlayHolder']
		if holder then
			WorldMapButton:SetParent(holder)
		end
	end

	-- ShaguTweaks
	if IsAddOnLoaded('ShaguTweaks') then
		if ShaguTweaks_config and ShaguTweaks_config["WorldMap Window"] == 1 then
			WorldMapScrollFrame:SetPoint('TOP', WorldMapFrame, 0, -48)
		end
	end

	-- pfQuest
	if IsAddOnLoaded('pfQuest') then
		local dropdown = _G['pfQuestMapDropdown']
		if dropdown then
			dropdown:ClearAllPoints()
			dropdown:SetParent(WorldMapFrame)
			dropdown:SetPoint('TOPRIGHT', 'WorldMapPositioningGuide', 0, -80)
			dropdown:SetFrameStrata('FULLSCREEN_DIALOG')

			if WORLDMAP_WINDOWED == 1 then
				dropdown:SetPoint('TOPRIGHT', 'WorldMapPositioningGuide', 0, -40)
			else
				dropdown:SetPoint('TOPRIGHT', 'WorldMapPositioningGuide', 0, -80)
			end
		end
	end

	if IsAddOnLoaded('pfUI') then
		if pfUI.map then
			WorldMapScrollFrame:SetPoint('TOP', WorldMapFrame, 0, -48)
		end
	end
end

local handler = CreateFrame('Frame')
handler:RegisterEvent('PLAYER_ENTERING_WORLD')
handler:SetScript('OnEvent', Magnify_HandleAddons)
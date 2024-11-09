local _G = getfenv(0)

local function HandleAddons()
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
			if WorldMapScrollFrame then
				WorldMapScrollFrame:SetPoint('TOP', WorldMapFrame, 0, -48)

				if WORLDMAP_WINDOWED and WORLDMAP_WINDOWED == 1 then
					WorldMapScrollFrame:SetPoint('TOP', WorldMapFrame, 2, -24)
				end
			end
		end
	end

	-- pfQuest
	if IsAddOnLoaded('pfQuest') then
		local dropdown = _G['pfQuestMapDropdown']
		if dropdown then
			dropdown:ClearAllPoints()
			dropdown:SetParent(WorldMapFrame)
			dropdown:SetFrameStrata('FULLSCREEN_DIALOG')

			if WORLDMAP_WINDOWED and WORLDMAP_WINDOWED == 1 then
				dropdown:SetPoint('TOPRIGHT', 'WorldMapPositioningGuide', 0, -36)
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
handler:SetScript('OnEvent', HandleAddons)

local WorldMapFrame_OldMinimize = WorldMapFrame_Minimize
function WorldMapFrame_Minimize()
	WorldMapFrame_OldMinimize()

	if WorldMapScrollFrame then
		MAGNIFY_MIN_ZOOM = 0.7

		WorldMapScrollFrame:SetWidth(702)
		WorldMapScrollFrame:SetHeight(468)
		WorldMapScrollFrame:SetPoint('TOP', WorldMapFrame, 2, -24)
		WorldMapScrollFrame:SetScrollChild(WorldMapDetailFrame)

		WorldMapButton:SetScale(1)

		WorldMapFrameAreaFrame:ClearAllPoints()
		WorldMapFrameAreaFrame:SetPoint('TOP', WorldMapFrame, 0, -15)

		Magnify_ResetZoom()
	end

	HandleAddons()
end

local WorldMapFrame_OldMaximize = WorldMapFrame_Maximize
function WorldMapFrame_Maximize()
	WorldMapFrame_OldMaximize()

	if WorldMapScrollFrame then
		MAGNIFY_MIN_ZOOM = 1

		WorldMapScrollFrame:SetWidth(1002)
		WorldMapScrollFrame:SetHeight(668)
		WorldMapScrollFrame:SetPoint('TOP', WorldMapFrame, 0, -70)
		WorldMapScrollFrame:SetScrollChild(WorldMapDetailFrame)

		WorldMapFrameAreaFrame:ClearAllPoints()
		WorldMapFrameAreaFrame:SetPoint('TOP', WorldMapFrame, 0, -60)

		Magnify_ResetZoom()
	end

	HandleAddons()
end
local _G = getfenv(0)

local Magnify_OnEvent = Magnify:GetScript('OnEvent')
Magnify:RegisterEvent('PLAYER_ENTERING_WORLD')
Magnify:SetScript('OnEvent',
    function()
        Magnify_OnEvent()

        if event == 'PLAYER_ENTERING_WORLD' then
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

            -- pfQuest
            if IsAddOnLoaded('pfQuest') then
                local dropdown = _G['pfQuestMapDropdown']
                if dropdown then
                    dropdown:ClearAllPoints()
                    dropdown:SetParent(WorldMapFrame)
                    dropdown:SetPoint('TOPRIGHT', 'WorldMapPositioningGuide', 0, -80)
                    dropdown:SetFrameStrata('FULLSCREEN_DIALOG')
                end
            end
        end
    end
)
local _G = getfenv(0)

local handler = CreateFrame('Frame')
handler:RegisterEvent('PLAYER_ENTERING_WORLD')
handler:SetScript('OnEvent',
    function()
        if event == 'PLAYER_ENTERING_WORLD' then
            -- Cartographer
            if IsAddOnLoaded('Cartographer') then
                CartographerGoToButton:ClearAllPoints()
                CartographerGoToButton:SetPoint('TOPLEFT', WorldMapPositioningGuide, 12, -35)

                CartographerOptionsButton:ClearAllPoints()
                CartographerOptionsButton:SetPoint('TOPRIGHT', WorldMapPositioningGuide, -12, -35)

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
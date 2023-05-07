local _G = getfenv(0)

local handler = CreateFrame('Frame')
handler:RegisterEvent('VARIABLES_LOADED')
handler:SetScript('OnEvent',
    function()
        if event == 'VARIABLES_LOADED' then
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
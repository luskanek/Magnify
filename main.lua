local ZOOM_MIN = 1
local ZOOM_MAX = 1.5
local ZOOM_STEP = 0.2

function WorldMapScrollFrame_OnPan(cursorX, cursorY)
	local dX = WorldMapScrollFrame.cursorX - cursorX
	local dY = cursorY - WorldMapScrollFrame.cursorY
	if abs(dX) >= 1 or abs(dY) >= 1 then
		WorldMapScrollFrame.moved = true
		
		local x
		x = max(0, dX - WorldMapScrollFrame.x)
		x = min(x, WorldMapScrollFrame.maxX)
		WorldMapScrollFrame:SetHorizontalScroll(-x)
		
		local y
		y = max(0, dY + WorldMapScrollFrame.y)
		y = min(y, WorldMapScrollFrame.maxY)
		WorldMapScrollFrame:SetVerticalScroll(y)
	end
end

Magnify = CreateFrame('Frame')
Magnify:RegisterEvent('VARIABLES_LOADED')
Magnify:SetScript('OnEvent',
	function()
		UIPanelWindows['WorldMapFrame'] = { area = 'center', pushable = 0, whileDead = 1 }
		
		-- adjust map zone text position
		WorldMapFrameAreaFrame:SetParent(WorldMapFrame)
		WorldMapFrameAreaFrame:ClearAllPoints()
		WorldMapFrameAreaFrame:SetPoint('TOP', WorldMapFrame, 0, -60)
		WorldMapFrameAreaFrame:SetFrameStrata('FULLSCREEN_DIALOG')
		
		-- hide clutter
		WorldMapMagnifyingGlassButton:Hide()
		
		BlackoutWorld:Hide()
	end
)

CreateFrame('ScrollFrame', 'WorldMapScrollFrame', WorldMapFrame, 'FauxScrollFrameTemplate')
WorldMapScrollFrame:SetHeight(668)
WorldMapScrollFrame:SetWidth(1002)
WorldMapScrollFrame:SetPoint('TOP', WorldMapFrame, 0, -70)
WorldMapScrollFrame:SetScrollChild(WorldMapDetailFrame)
WorldMapScrollFrame:SetScript('OnMouseWheel',
	function()
		local oldScrollH = WorldMapScrollFrame:GetHorizontalScroll()
		local oldScrollV = WorldMapScrollFrame:GetVerticalScroll()
		
		local cursorX, cursorY = GetCursorPosition()
		
		local frameX = cursorX - WorldMapScrollFrame:GetLeft()
		local frameY = WorldMapScrollFrame:GetTop() - cursorY
		
		local oldScale = WorldMapDetailFrame:GetScale()
		local newScale
		newScale = oldScale + arg1 * ZOOM_STEP
		newScale = max(ZOOM_MIN, newScale)
		newScale = min(ZOOM_MAX, newScale)
		
		WorldMapDetailFrame:SetScale(newScale)
		
		WorldMapScrollFrame.maxX = ((WorldMapDetailFrame:GetWidth() * newScale) - WorldMapScrollFrame:GetWidth()) / newScale
		WorldMapScrollFrame.maxY = ((WorldMapDetailFrame:GetHeight() * newScale) - WorldMapScrollFrame:GetHeight()) / newScale
		WorldMapScrollFrame.zoomedIn = WorldMapDetailFrame:GetScale() > ZOOM_MIN
		
		local scaleChange = newScale / oldScale
		local newScrollH = scaleChange * (frameX - oldScrollH) - frameX
		local newScrollV = scaleChange * (frameY + oldScrollV) - frameY
		
		newScrollH = min(newScrollH, WorldMapScrollFrame.maxX)
		newScrollH = max(0, newScrollH)
		newScrollV = min(newScrollV, WorldMapScrollFrame.maxY)
		newScrollV = max(0, newScrollV)
		
		WorldMapScrollFrame:SetHorizontalScroll(-newScrollH)
		WorldMapScrollFrame:SetVerticalScroll(newScrollV)
	end
)

local WorldMapFrame_OnShow = WorldMapFrame:GetScript('OnShow')
WorldMapFrame:SetScript('OnShow',
	function()
		WorldMapFrame_OnShow()
		
		WorldMapPing:Hide()
		WorldMapScrollFrameScrollBar:Hide()
	end
)

WorldMapButton:SetParent(WorldMapDetailFrame)
WorldMapButton:SetScript('OnMouseDown',
	function()
		if arg1 == 'LeftButton' and WorldMapScrollFrame.zoomedIn then
			WorldMapScrollFrame.panning = true
			local x, y = GetCursorPosition()
			WorldMapScrollFrame.cursorX = x
			WorldMapScrollFrame.cursorY = y
			WorldMapScrollFrame.x = WorldMapScrollFrame:GetHorizontalScroll()
			WorldMapScrollFrame.y = WorldMapScrollFrame:GetVerticalScroll()
			WorldMapScrollFrame.moved = false
		end
	end
)

local WorldMapButton_OnMouseUp = WorldMapButton:GetScript('OnMouseUp')
WorldMapButton:SetScript('OnMouseUp',
	function()
		if arg1 == 'LeftButton' and WorldMapScrollFrame.panning then
			WorldMapScrollFrame.panning = false
		elseif (arg1 == 'LeftButton' or arg1 == 'RightButton') and not WorldMapScrollFrame.zoomedIn then
			WorldMapButton_OnMouseUp()
		end
	end
)

local WorldMapButton_OnUpdate = WorldMapButton:GetScript('OnUpdate')
WorldMapButton:SetScript('OnUpdate',
	function()
		WorldMapButton_OnUpdate()
		
		-- reposition player
		local x, y = GetPlayerMapPosition('player')
		
		x = (x * WorldMapDetailFrame:GetWidth() * WorldMapDetailFrame:GetScale())
		y = (-y * WorldMapDetailFrame:GetHeight() * WorldMapDetailFrame:GetScale())
		
		PositionWorldMapArrowFrame('CENTER', 'WorldMapDetailFrame', 'TOPLEFT', x, y)
		WorldMapPlayer:SetPoint('CENTER', 'WorldMapDetailFrame', 'TOPLEFT', x, y)
		
		if WorldMapScrollFrame.panning then
			WorldMapScrollFrame_OnPan(GetCursorPosition())
		end
	end
)

local WorldMapFrame_OnShow = WorldMapFrame:GetScript('OnShow')
WorldMapFrame:SetScript('OnShow',
	function()
		WorldMapFrame_OnShow()
		
		this:ClearAllPoints()
		this:SetPoint('CENTER', UIParent, 0, 0)
		this:SetScale(0.75)
		this:SetHeight(768)
		this:SetWidth(1024)
		this:EnableMouse(true)
		this:EnableKeyboard(false)
	end
)
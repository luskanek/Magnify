local ZOOM_MIN = 1
local ZOOM_MAX = 1.6
local ZOOM_STEP = 0.2

local WorldMapPlayerModel = nil

-- upvalues
local abs = math.abs
local cos, sin = math.cos, math.sin
local min, max = math.min, math.max
local rad = math.rad
local sqrt = math.sqrt

local GetCursorPosition = GetCursorPosition
local GetPlayerMapPosition = GetPlayerMapPosition

local function WorldMapScrollFrame_OnMouseWheel()
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

local function WorldMapScrollFrame_OnPan(cursorX, cursorY)
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

local function WorldMapButton_OnMouseDown()
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

local function WorldMapButton_OnMouseUp()
	WorldMapScrollFrame.panning = false

	if not WorldMapScrollFrame.moved then
		WorldMapButton_OnClick(arg1)

		WorldMapDetailFrame:SetScale(1)

		WorldMapScrollFrame:SetHorizontalScroll(0)
		WorldMapScrollFrame:SetVerticalScroll(0)

		WorldMapScrollFrame.zoomedIn = false
	end

	WorldMapScrollFrame.moved = false
end

local WorldMapButton_OldOnUpdate = WorldMapButton:GetScript('OnUpdate')
local function WorldMapButton_OnUpdate()
	WorldMapButton_OldOnUpdate()

	-- reposition player and ping indicators
	local x, y = GetPlayerMapPosition('player')

	x = x * this:GetWidth()
	y = -y * this:GetHeight()

	WorldMapPlayer:SetPoint('CENTER', this, 'TOPLEFT', x, y)

	-- credit: https://wowwiki-archive.fandom.com/wiki/SetTexCoord_Transformations
	local s = sqrt(2)
	local r = WorldMapPlayerModel:GetFacing()

	local LRx, LRy = 0.5 + cos(r + 0.25 * math.pi) / s, 0.5 + sin(r + 0.25 * math.pi) / s
	local LLx, LLy = 0.5 + cos(r + 0.75 * math.pi) / s, 0.5 + sin(r + 0.75 * math.pi) / s
	local ULx, ULy = 0.5 + cos(r + 1.25 * math.pi) / s, 0.5 + sin(r + 1.25 * math.pi) / s
	local URx, URy = 0.5 + cos(r - 0.25 * math.pi) / s, 0.5 + sin(r - 0.25 * math.pi) / s

	WorldMapPlayerIcon:SetTexCoord(ULx, ULy, LLx, LLy, URx, URy, LRx, LRy)

	WorldMapPing:SetPoint('CENTER', this, 'TOPLEFT', x * WorldMapDetailFrame:GetScale() - 8, y * WorldMapDetailFrame:GetScale() - 8)

	if WorldMapScrollFrame.panning then
		WorldMapScrollFrame_OnPan(GetCursorPosition())
	end
end

local WorldMapFrame_OldOnHide = WorldMapFrame:GetScript('OnHide')
local function WorldMapFrame_OnHide()
	WorldMapFrame_OldOnHide()

	WorldMapScrollFrame.panning = false

	if Magnify_Settings['zoom_reset'] then
		WorldMapDetailFrame:SetScale(1)

		WorldMapScrollFrame:SetHorizontalScroll(0)
		WorldMapScrollFrame:SetVerticalScroll(0)

		WorldMapScrollFrame.zoomedIn = false
	end
end

local function HandleEvent()
	if not Magnify_Settings then
		Magnify_Settings = {
			['zoom_reset'] = false
		}
	end

	local scrollframe = CreateFrame('ScrollFrame', 'WorldMapScrollFrame', WorldMapFrame, 'FauxScrollFrameTemplate')
	scrollframe:SetHeight(668)
	scrollframe:SetWidth(1002)
	scrollframe:SetPoint('TOP', WorldMapFrame, 0, -70)
	scrollframe:SetScrollChild(WorldMapDetailFrame)
	scrollframe:SetScript('OnMouseWheel', WorldMapScrollFrame_OnMouseWheel)

	WorldMapScrollFrameScrollBar:Hide()

	-- adjust map zone text position
	WorldMapFrameAreaFrame:SetParent(WorldMapFrame)
	WorldMapFrameAreaFrame:ClearAllPoints()
	WorldMapFrameAreaFrame:SetPoint('TOP', WorldMapFrame, 0, -60)
	WorldMapFrameAreaFrame:SetFrameStrata('FULLSCREEN_DIALOG')

	WorldMapButton:SetParent(WorldMapDetailFrame)

	-- hide clutter
	WorldMapMagnifyingGlassButton:Hide()

	-- hide player indicator model
	-- credit: https://github.com/Road-block/Cartographer
	local children = { WorldMapFrame:GetChildren() }
	for _, v in ipairs(children) do
		if v:GetFrameType() == 'Model' and not v:GetName() then
			v:SetScript('OnShow', function() this:Hide() end)

			WorldMapPlayerModel = v

			break
		end
	end

	-- replace player indicator model with a better solution
	WorldMapPlayer.Icon = WorldMapPlayer:CreateTexture('WorldMapPlayerIcon', 'ARTWORK')
	WorldMapPlayer.Icon:SetWidth(24)
	WorldMapPlayer.Icon:SetHeight(24)
	WorldMapPlayer.Icon:SetPoint('CENTER', WorldMapPlayer)
	WorldMapPlayer.Icon:SetTexture('Interface\\AddOns\\Magnify\\assets\\WorldMapArrow')
	WorldMapPlayer.Icon:SetTexCoord(0, 0, 1, 1)

	WorldMapPing:SetParent(WorldMapScrollFrame)

	-- override scripts
	WorldMapButton:SetScript('OnMouseDown', WorldMapButton_OnMouseDown)
	WorldMapButton:SetScript('OnMouseUp', WorldMapButton_OnMouseUp)
	WorldMapButton:SetScript('OnUpdate', WorldMapButton_OnUpdate)

	WorldMapFrame:SetScript('OnHide', WorldMapFrame_OnHide)
end

local handler = CreateFrame('Frame')
handler:RegisterEvent('VARIABLES_LOADED')
handler:SetScript('OnEvent', HandleEvent)

SLASH_MAGNIFY1 = '/magnify'
SlashCmdList['MAGNIFY'] = function(msg)
	local args = {}
	local i = 1
	for arg in string.gfind(string.lower(msg), '%S+') do
		args[i] = arg
		i = i + 1
	end

	if not args[1] then
		DEFAULT_CHAT_FRAME:AddMessage('/magnify reset - toggle world map zoom reset when closing the world map')

	elseif args[1] == 'reset' then
		Magnify_Settings['zoom_reset'] = not Magnify_Settings['zoom_reset']

		DEFAULT_CHAT_FRAME:AddMessage('World map zoom reset ' .. (Magnify_Settings['zoom_reset'] and 'enabled' or 'disabled') .. '.')
	end
end
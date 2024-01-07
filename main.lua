MAGNIFY_MAX_ZOOM = 1.6
MAGNIFY_ZOOM_STEP = 0.2
MAGNIFY_PLAYER_FLASH_INTERVAL = 0.25
MAGNIFY_PLAYER_FLASH_COUNT = 10

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
	newScale = oldScale + arg1 * MAGNIFY_ZOOM_STEP
	newScale = max(1, newScale)
	newScale = min(MAGNIFY_MAX_ZOOM, newScale)

	WorldMapDetailFrame:SetScale(newScale)

	WorldMapScrollFrame.maxX = ((WorldMapDetailFrame:GetWidth() * newScale) - WorldMapScrollFrame:GetWidth()) / newScale
	WorldMapScrollFrame.maxY = ((WorldMapDetailFrame:GetHeight() * newScale) - WorldMapScrollFrame:GetHeight()) / newScale
	WorldMapScrollFrame.zoomedIn = WorldMapDetailFrame:GetScale() > 1

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
	if WorldMapScrollFrame.panning then
		WorldMapScrollFrame_OnPan(GetCursorPosition())
	end
end

local function WorldMapPlayer_OnUpdate()
	this.Elapsed = this.Elapsed + arg1

	if this.Elapsed > MAGNIFY_PLAYER_FLASH_INTERVAL then
		this.Elapsed = 0

		if this.Flashes < MAGNIFY_PLAYER_FLASH_COUNT then
			this.Flashes = this.Flashes + 1

			if this:GetAlpha() == 1 then
				this:SetAlpha(0)
			else
				this:SetAlpha(1)
			end
		else
			this.Flashes = 0
			this:SetAlpha(1)
			this:SetScript('OnUpdate', nil)
		end
	end
end

local WorldMapFrame_OldOnShow = WorldMapFrame:GetScript('OnShow')
local function WorldMapFrame_OnShow()
	WorldMapFrame_OldOnShow()

	if Magnify_Settings['arrow_flash'] then
		WorldMapPlayer:SetScript('OnUpdate', WorldMapPlayer_OnUpdate)
	end
end

local WorldMapFrame_OldOnHide = WorldMapFrame:GetScript('OnHide')
local function WorldMapFrame_OnHide()
	WorldMapFrame_OldOnHide()

	WorldMapScrollFrame.panning = false

	WorldMapPlayer.Flashes = 0
	WorldMapPlayer:SetScript('OnUpdate', nil)

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
			['arrow_flash'] = true,
			['arrow_scale'] = 1,
			['max_zoom'] = 1.6,
			['zoom_reset'] = false
		}
	end

	MAGNIFY_MAX_ZOOM = (Magnify_Settings['max_zoom'] or MAGNIFY_MAX_ZOOM)

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

	-- hide player indicator and ping model
	-- credit: https://github.com/Road-block/Cartographer
	local children = { WorldMapFrame:GetChildren() }
	for _, v in ipairs(children) do
		if v:GetFrameType() == 'Model' and not v:GetName() then
			v:SetScript('OnShow', function() this:Hide() end)

			WorldMapPlayerModel = v

			break
		end
	end

	WorldMapPing.Show = function() return end

	-- replace player indicator model with a better solution
	local size = 24 * (Magnify_Settings['arrow_scale'] or 1)

	WorldMapPlayer.Icon = WorldMapPlayer:CreateTexture('WorldMapPlayerIcon', 'ARTWORK')
	WorldMapPlayer.Icon:SetWidth(size)
	WorldMapPlayer.Icon:SetHeight(size)
	WorldMapPlayer.Icon:SetPoint('CENTER', WorldMapPlayer)
	WorldMapPlayer.Icon:SetTexture('Interface\\AddOns\\Magnify\\assets\\WorldMapArrow')
	WorldMapPlayer.Icon:SetTexCoord(0, 0, 1, 1)

	WorldMapPlayer.Flashes = 0
	WorldMapPlayer.Elapsed = 0

	-- override scripts
	WorldMapButton:SetScript('OnMouseDown', WorldMapButton_OnMouseDown)
	WorldMapButton:SetScript('OnMouseUp', WorldMapButton_OnMouseUp)
	WorldMapButton:SetScript('OnUpdate', WorldMapButton_OnUpdate)

	WorldMapFrame:SetScript('OnShow', WorldMapFrame_OnShow)
	WorldMapFrame:SetScript('OnHide', WorldMapFrame_OnHide)
end

local handler = CreateFrame('Frame')
handler:RegisterEvent('VARIABLES_LOADED')
handler:SetScript('OnEvent', HandleEvent)
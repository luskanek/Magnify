MAGNIFY_MIN_ZOOM = 1.0
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

--Fix covering players and map poi
WorldMapFrameScrollFrame:SetFrameLevel(1)

function WorldMapFrameScrollFrame_OnMouseDown()
	if arg1 == 'LeftButton' and this.zoomedIn then
		this.panning = true

		local x, y = GetCursorPosition()

		this.cursorX = x
		this.cursorY = y
		this.x = this:GetHorizontalScroll()
		this.y = this:GetVerticalScroll()
		this.moved = false
	end
end

function WorldMapFrameScrollFrame_OnMouseUp()
	this.panning = false

	if not this.moved then
		WorldMapButton_OnClick(arg1)

		WorldMapDetailFrame:SetScale(MAGNIFY_MIN_ZOOM)

		this:SetHorizontalScroll(0)
		this:SetVerticalScroll(0)

		this.zoomedIn = false
	end

	this.moved = false
end

function WorldMapFrameScrollFrame_OnMouseWheel()
	local oldScrollH = this:GetHorizontalScroll()
	local oldScrollV = this:GetVerticalScroll()

	local cursorX, cursorY = GetCursorPosition()
	cursorX = cursorX / this:GetEffectiveScale()
	cursorY = cursorY / this:GetEffectiveScale()

	local frameX = cursorX - this:GetLeft()
	local frameY = this:GetTop() - cursorY

	local oldScale = WorldMapDetailFrame:GetScale()
	local newScale
	newScale = oldScale + arg1 * MAGNIFY_ZOOM_STEP
	newScale = max(MAGNIFY_MIN_ZOOM, newScale)
	newScale = min(MAGNIFY_MAX_ZOOM, newScale)

	WorldMapDetailFrame:SetScale(newScale)

	this.maxX = ((WorldMapDetailFrame:GetWidth() * newScale) - this:GetWidth()) / newScale
	this.maxY = ((WorldMapDetailFrame:GetHeight() * newScale) - this:GetHeight()) / newScale
	this.zoomedIn = WorldMapDetailFrame:GetScale() > MAGNIFY_MIN_ZOOM

	local centerX = -oldScrollH + frameX / oldScale
	local centerY = oldScrollV + frameY / oldScale
	local newScrollH = centerX - frameX / newScale
	local newScrollV = centerY - frameY / newScale

	newScrollH = min(newScrollH, this.maxX)
	newScrollH = max(0, newScrollH)
	newScrollV = min(newScrollV, this.maxY)
	newScrollV = max(0, newScrollV)

	this:SetHorizontalScroll(-newScrollH)
	this:SetVerticalScroll(newScrollV)
end

local function WorldMapFrameScrollFrame_OnPan(cursorX, cursorY)
	local dX = WorldMapFrameScrollFrame.cursorX - cursorX
	local dY = cursorY - WorldMapFrameScrollFrame.cursorY
	dX = dX / this:GetEffectiveScale()
	dY = dY / this:GetEffectiveScale()
	if abs(dX) >= 1 or abs(dY) >= 1 then
		WorldMapFrameScrollFrame.moved = true

		local x
		x = max(0, dX - WorldMapFrameScrollFrame.x)
		x = min(x, WorldMapFrameScrollFrame.maxX)
		WorldMapFrameScrollFrame:SetHorizontalScroll(-x)

		local y
		y = max(0, dY + WorldMapFrameScrollFrame.y)
		y = min(y, WorldMapFrameScrollFrame.maxY)
		WorldMapFrameScrollFrame:SetVerticalScroll(y)
	end
end

local WorldMapButton_OldOnUpdate = WorldMapButton:GetScript('OnUpdate')
local function WorldMapButton_OnUpdate()
	WorldMapButton_OldOnUpdate()

	-- reposition player and ping indicators
	local x, y = GetPlayerMapPosition('player')

	if x == 0 and y == 0 then
		WorldMapPlayer.Icon:Hide()
	else
		WorldMapPlayer.Icon:Show()

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
		if WorldMapFrameScrollFrame.panning then
			WorldMapFrameScrollFrame_OnPan(GetCursorPosition())
		end
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
	else
		WorldMapPlayer:SetAlpha(1)
	end
end

local WorldMapFrame_OldOnHide = WorldMapFrame:GetScript('OnHide')
local function WorldMapFrame_OnHide()
	WorldMapFrame_OldOnHide()

	WorldMapFrameScrollFrame.panning = false

	WorldMapPlayer.Flashes = 0
	WorldMapPlayer:SetScript('OnUpdate', nil)

	if Magnify_Settings['zoom_reset'] then
		Magnify_ResetZoom()
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

	if WORLDMAP_WINDOWED then
		if WORLDMAP_WINDOWED == 1 then
			WorldMapFrame_Minimize()
		else
			WorldMapFrame_Maximize()
		end
	end

	-- adjust map zone text position
	WorldMapFrameAreaFrame:SetParent(WorldMapFrame)
	WorldMapFrameAreaFrame:ClearAllPoints()
	WorldMapFrameAreaFrame:SetPoint('TOP', WorldMapFrame, 0, -60)
	WorldMapFrameAreaFrame:SetFrameStrata('FULLSCREEN_DIALOG')

	WorldMapButton:SetParent(WorldMapDetailFrame)
	WorldMapButton:SetFrameLevel(0)

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
	WorldMapPing:SetModelScale(0)

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
	WorldMapButton:SetScript('OnUpdate', WorldMapButton_OnUpdate)

	WorldMapFrame:SetScript('OnShow', WorldMapFrame_OnShow)
	WorldMapFrame:SetScript('OnHide', WorldMapFrame_OnHide)
end

local handler = CreateFrame('Frame')
handler:RegisterEvent('VARIABLES_LOADED')
handler:SetScript('OnEvent', HandleEvent)

function Magnify_ResetZoom()
	WorldMapDetailFrame:SetScale(MAGNIFY_MIN_ZOOM)

	WorldMapFrameScrollFrame:SetHorizontalScroll(0)
	WorldMapFrameScrollFrame:SetVerticalScroll(0)

	WorldMapFrameScrollFrame.zoomedIn = false
end

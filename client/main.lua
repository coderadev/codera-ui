
local TXD = 'codera_ui_hud'
local TEXTURES = { 'key', 'dot', 'crosshair', 'font' }

local P = Config.Prompt
local font = PromptFont
local glyphs = font.glyphs

Config.Players = Config.Players or {}


local txdReady = false
local function loadTxd()
    if txdReady then return end
    local txd = CreateRuntimeTxd(TXD)
    for i = 1, #TEXTURES do
        local name = TEXTURES[i]
        CreateRuntimeTextureFromImage(txd, name, 'ui/hud/' .. name .. '.png')
    end
    txdReady = true
end

CreateThread(loadTxd)


local NOT_A_KEY = {
    left = true, right = true, top = true, bottom = true, center = true,
    info = true, error = true, success = true, warning = true, primary = true,
}

local function resolveKey(key)
    if key == nil or NOT_A_KEY[key] then
        return (Config.DefaultKey and Config.DefaultKey.Key) or 'E'
    end
    return key
end

local function nuiPayload(action, text, key, hide)
    local msg = { action = action, show = true, hide = hide }
    if type(text) == 'table' then
        msg.hints = text
    else
        msg.key = resolveKey(key)
        msg.text = text
    end
    return msg
end

function displayTextUI(text, key, hide)
    SendNUIMessage(nuiPayload('textUI', text, key, hide))
end

function changeText(text, key)
    SendNUIMessage(nuiPayload('textUIUpdate', text, key))
end

function hideTextUI()
    SendNUIMessage({ action = 'textUI', show = false })
end


local function alwaysTrue() return true end

local function buildClick(data, triggerData)
    return function()
        if triggerData then
            if triggerData.isServer then
                TriggerServerEvent(triggerData.triggerName, triggerData.args)
            else
                TriggerEvent(triggerData.triggerName, triggerData.args)
            end
        elseif data.onKeyClick then
            data.onKeyClick()
        end
    end
end

function create3DTextUI(id, data)
    if Config.Areas[id] then
        print(tostring(id) .. ' already exist.')
        return
    end

    local c = data.coords or vector3(0.0, 0.0, 0.0)
    Config.Areas[id] = {
        data = {
            id = id,
            type = data.type or '3dtext', 
            coords = vector3(c.x, c.y, c.z),
            offset = data.offset,
            displayDist = data.displayDist or 6.0,
            interactDist = data.interactDist or 2.0,
            dist = data.dist, -- textui type only
            enableKeyClick = data.enableKeyClick,
            keyNum = data.keyNum or 38,
            key = data.key,
            text = data.text,
            theme = data.theme or 'green',
            job = data.job or 'all',
            canInteract = data.canInteract or alwaysTrue,
        },
        onKeyClick = buildClick(data, data.triggerData),
    }
end

function create3DTextUIOnEntity(id, data)
    if Config.Areas[id] then
        print(tostring(id) .. ' already exist.')
        return
    end

    local isEntity = type(id) == 'number' and DoesEntityExist(id)
    if isEntity then
        local c = GetEntityCoords(id)
        data.coords = vector3(c.x, c.y, c.z + 1.0)
        data.type = '3dtextentity'
    else
        data.coords = vector3(0.0, 0.0, 0.0)
        data.type = '3dtexthash'
    end
    create3DTextUI(id, data)
end

function update3DTextUI(id, text, theme)
    local area = Config.Areas[id]
    if not area then
        print(tostring(id) .. ' doesnt exist.')
        return
    end
    if text ~= nil then area.data.text = text end
    if theme ~= nil then area.data.theme = theme end
end

function delete3DTextUI(id)
    if Config.Areas[id] then
        Config.Areas[id] = nil
    else
        print(tostring(id) .. ' doesnt exist.')
    end
end

function create3DTextUIOnPlayers(id, data)
    if Config.Players[id] then
        print(tostring(id) .. ' already exist.')
        return
    end

    Config.Players[id] = {
        data = {
            id = id,
            serverId = data.id,
            ped = data.ped,
            offset = data.offset,
            displayDist = data.displayDist or 6.0,
            interactDist = data.interactDist or 2.0,
            enableKeyClick = data.enableKeyClick,
            keyNum = data.keyNum or 38,
            keyNum2 = data.keyNum2,
            key = data.key,
            text = data.text,
            theme = data.theme or 'green',
        },
        onKeyClick = buildClick(data, data.triggerData),
        onKeyClick2 = buildClick({}, data.triggerData2),
    }
end

function delete3DTextUIOnPlayers(id)
    if Config.Players[id] then
        Config.Players[id] = nil
        return
    end
    -- also accept the target's server id (as in the docs)
    for k, v in pairs(Config.Players) do
        if v.data.serverId == id then
            Config.Players[k] = nil
            return
        end
    end
    print(tostring(id) .. ' doesnt exist.')
end


local string_sub = string.sub
local textCache = {}
local textCacheSize = 0

local function cleanText(text, upper)
    text = tostring(text or '')
    local cacheKey = upper and ('U' .. text) or ('N' .. text)
    local cached = textCache[cacheKey]
    if cached then return cached end

    local out = text:gsub('<[^>]*>', ''):gsub('[\194-\244][\128-\191]*', '?')
    if upper then out = out:upper() end

    if textCacheSize > 256 then textCache, textCacheSize = {}, 0 end
    textCache[cacheKey] = out
    textCacheSize = textCacheSize + 1
    return out
end

local function drawGlyphs(text, x, centerY, capHeight, aspect, r, g, b, a)
    local k = capHeight / font.capHeight
    local h = font.lineHeight * k
    local cy = centerY + capHeight * 0.5 - font.ascent * k + h * 0.5
    local kx = k / aspect
    local vh = font.lineHeight / font.height
    local pen = x

    for i = 1, #text do
        local glyph = glyphs[string_sub(text, i, i)] or glyphs['?']
        if glyph.w > 0 then
            local u, v = glyph.x / font.width, glyph.y / font.height
            DrawSpriteUv(TXD, 'font', pen + (glyph.xoff + glyph.w * 0.5) * kx, cy, glyph.w * kx, h,
                u, v, u + glyph.w / font.width, v + vh, 0.0, r, g, b, a)
        end
        pen = pen + glyph.adv * kx
    end

    return pen - x
end

local function measureText(text, capHeight, aspect)
    local kx = capHeight / font.capHeight / aspect
    local width = 0.0
    for i = 1, #text do
        width = width + (glyphs[string_sub(text, i, i)] or glyphs['?']).adv * kx
    end
    return width
end

local function drawText(text, x, centerY, capHeight, aspect, color)
    if P.shadowAlpha > 0 then
        local offset = capHeight * 0.08
        drawGlyphs(text, x + offset / aspect, centerY + offset, capHeight, aspect, 0, 0, 0,
            math.floor(P.shadowAlpha * color[4] / 255))
    end
    drawGlyphs(text, x, centerY, capHeight, aspect, color[1], color[2], color[3], color[4])
end

local function themeColor(theme)
    return Config.Themes[theme or 'green'] or Config.Themes.green or { 255, 255, 255 }
end

local function drawDot(coords, color, aspect)
    local size = P.dotSize
    SetDrawOrigin(coords.x, coords.y, coords.z, 0)
    DrawSprite(TXD, 'dot', 0.0, 0.0, size / aspect, size, 0.0, color[1], color[2], color[3], 255)
    ClearDrawOrigin()
end

local function drawCrosshair(aspect)
    local size = P.crosshairSize
    DrawSprite(TXD, 'crosshair', 0.5, 0.5, size / aspect, size, 0.0, 255, 255, 255, 255)
end

-- "[E] LABEL": the key badge sits on the point, the label to its right.
local function drawPrompt(coords, key, label, color, aspect)
    local keyH = P.keySize
    local minW = keyH / aspect
    local keyTextW = measureText(key, P.keyTextHeight, aspect)
    local keyW = math.max(minW, keyTextW + minW * 0.7) -- longer key names (LALT, F5...) widen the badge
    local labelX = keyW * 0.5 + P.keyGap / aspect
    local kt = P.keyTextColor

    SetDrawOrigin(coords.x, coords.y, coords.z, 0)
    DrawSprite(TXD, 'key', 0.0, 0.0, keyW, keyH, 0.0, color[1], color[2], color[3], 255)
    drawGlyphs(key, -keyTextW * 0.5, 0.0, P.keyTextHeight, aspect, kt[1], kt[2], kt[3], kt[4])
    drawText(label, labelX, 0.0, P.textHeight, aspect, P.textColor)
    ClearDrawOrigin()
end


local currentJob = nil

local function jobAllowed(d)
    local job = d.job
    if job == nil or job == 'all' then return true end
    if type(job) == 'table' then
        for i = 1, #job do
            if job[i] == currentJob then return true end
        end
        return false
    end
    return job == currentJob
end

local function canInteract(d)
    local fn = d.canInteract
    if not fn then return true end
    local ok, res = pcall(fn)
    return ok and res and true or false
end

local function fire(fn)
    if not fn then return end
    local ok, err = pcall(fn)
    if not ok then print(('[codera-ui] key click error: %s'):format(tostring(err))) end
end


local SCAN_MARGIN = 8.0 
local nearby = {}
local nearbyCount = 0

local function coordsOf(v)
    local kind, d = v._kind, v.data
    local c
    if kind == 'area' then
        c = d.coords
    else
        local ent = (kind == 'hash') and v._ent or d.ped
        if not ent or not DoesEntityExist(ent) then return nil end
        c = GetEntityCoords(ent)
        if kind == 'hash' then c = vector3(c.x, c.y, c.z + 1.0) end
    end

    local o = d.offset
    if o then c = vector3(c.x + o.x, c.y + o.y, c.z + o.z) end
    return c
end

CreateThread(function()
    while true do
        local pc = GetEntityCoords(PlayerPedId())

        local ok, job = pcall(GetPlayerJob)
        currentJob = ok and job or nil

        local list, n = {}, 0

        for _, v in pairs(Config.Areas) do
            local d = v.data
            local t = d.type
            d.displayDist = d.displayDist or 6.0
            d.interactDist = d.interactDist or 2.0
            if t == '3dtext' then
                v._kind = 'area'
            elseif t == '3dtextentity' then
                v._kind = 'entity'
                d.ped = d.id -- reuse the generic "entity" slot
            elseif t == '3dtexthash' then
                v._kind = 'hash'
                local hash = type(d.id) == 'number' and d.id or joaat(d.id)
                local range = math.max(10.0, d.displayDist + SCAN_MARGIN)
                local obj = GetClosestObjectOfType(pc.x, pc.y, pc.z, range, hash, false, 0, 0)
                v._ent = (obj and obj ~= 0 and DoesEntityExist(obj)) and obj or nil
            else
                v._kind = nil -- 'textui' is handled by its own thread
            end

            if v._kind then
                local c = coordsOf(v)
                if c and #(c - pc) <= d.displayDist + SCAN_MARGIN then
                    n = n + 1
                    list[n] = v
                end
            end
        end

        for _, v in pairs(Config.Players) do
            local d = v.data
            v._kind = 'player'
            if d.serverId then
                local pl = GetPlayerFromServerId(d.serverId)
                if pl and pl ~= -1 then d.ped = GetPlayerPed(pl) end
            end
            local c = coordsOf(v)
            if c and #(c - pc) <= d.displayDist + SCAN_MARGIN then
                n = n + 1
                list[n] = v
            end
        end

        nearby, nearbyCount = list, n
        Wait(250)
    end
end)


local pool = {}

local function isDisabled()
    if P.disableOnNuiFocus and IsNuiFocused() then return true end
    local ped = PlayerPedId()
    if P.disableOnDeath and IsPedDeadOrDying(ped, true) then return true end
    if P.disableInVehicle and IsPedInAnyVehicle(ped, false) then return true end
    return false
end

local function render()
    local aspect = GetAspectRatio(false)
    local pc = GetEntityCoords(PlayerPedId())
    local count = 0
    local active, activeIndex
    local bestScore = P.requireHover and P.hoverRadius or math.huge

    for i = 1, nearbyCount do
        local v = nearby[i]
        local d = v.data
        local c = coordsOf(v)

        if c and jobAllowed(d) then
            local dist = #(c - pc)
            if dist <= d.displayDist and canInteract(d) then
                local onScreen, sx, sy = GetScreenCoordFromWorldCoord(c.x, c.y, c.z)
                if onScreen then
                    count = count + 1
                    local item = pool[count]
                    if not item then item = {} pool[count] = item end
                    item.v, item.coords = v, c

                    if dist <= d.interactDist then
                        local score
                        if P.requireHover then
                            local dx, dy = (sx - 0.5) * aspect, sy - 0.5
                            score = math.sqrt(dx * dx + dy * dy)
                        else
                            score = dist
                        end
                        if score < bestScore then
                            bestScore = score
                            active, activeIndex = item, count
                        end
                    end
                end
            end
        end
    end

    if count == 0 then return end

    for i = 1, count do
        if i ~= activeIndex then
            local item = pool[i]
            drawDot(item.coords, themeColor(item.v.data.theme), aspect)
        end
    end

    if P.crosshair then drawCrosshair(aspect) end
    if not active then return end

    local v = active.v
    local d = v.data
    local key = cleanText(d.key or resolveKey(nil), true)
    local label = cleanText(d.text, P.uppercase)
    drawPrompt(active.coords, key, label, themeColor(d.theme), aspect)

    if d.enableKeyClick then
        if d.keyNum and IsControlJustPressed(0, d.keyNum) then
            fire(v.onKeyClick)
        end
        if d.keyNum2 and IsControlJustPressed(0, d.keyNum2) then
            fire(v.onKeyClick2)
        end
    end
end

CreateThread(function()
    loadTxd()
    while true do
        local sleep = 500
        if nearbyCount > 0 and not isDisabled() then
            sleep = 0
            render()
        end
        Wait(sleep)
    end
end)


CreateThread(function()
    while true do
        local pc = GetEntityCoords(PlayerPedId())
        local bestId, best, bestDist

        for id, v in pairs(Config.Areas) do
            local d = v.data
            if d.type == 'textui' then
                local dist = #(d.coords - pc)
                if dist <= (d.dist or 3.0) and jobAllowed(d) and canInteract(d) then
                    if not bestDist or dist < bestDist then
                        bestId, best, bestDist = id, v, dist
                    end
                end
            end
        end

        if best then
            local d = best.data
            SendNUIMessage({ action = 'textUI', show = true, key = resolveKey(d.key), text = d.text })

            while Config.Areas[bestId] == best do
                Wait(0)
                if #(d.coords - GetEntityCoords(PlayerPedId())) > (d.dist or 3.0) then break end
                if d.keyNum and IsControlJustPressed(0, d.keyNum) then
                    fire(best.onKeyClick)
                end
            end

            SendNUIMessage({ action = 'textUI', show = false })
        end

        Wait(best and 0 or 250)
    end
end)

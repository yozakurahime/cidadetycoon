Utils = {}

---------------------------------------------------
-- Math
---------------------------------------------------
function Utils.Lerp(a, b, t)
    return a + (b - a) * t
end

function Utils.LerpVector3(v1, v2, t)
    return vector3(
        Utils.Lerp(v1.x, v2.x, t),
        Utils.Lerp(v1.y, v2.y, t),
        Utils.Lerp(v1.z, v2.z, t)
    )
end

function Utils.LerpAngle(a, b, t)
    local num = (b - a) % 360.0
    if num > 180.0 then num = num - 360.0 end
    return a + num * t
end

function Utils.LerpRotation(r1, r2, t)
    return vector3(
        Utils.LerpAngle(r1.x, r2.x, t),
        Utils.LerpAngle(r1.y, r2.y, t),
        Utils.LerpAngle(r1.z, r2.z, t)
    )
end

function Utils.Distance(a, b)
    return #(a - b)
end

---------------------------------------------------
-- Time formatting
---------------------------------------------------
function Utils.FormatTime(ms)
    if not ms then return "00:00.000" end
    local minutes = math.floor(ms / 60000)
    local seconds = math.floor((ms % 60000) / 1000)
    local millis  = math.floor(ms % 1000)
    return string.format("%02d:%02d.%03d", minutes, seconds, millis)
end

---------------------------------------------------
-- 2D Drawing (screen space)
---------------------------------------------------
function Utils.DrawText2D(text, x, y, scale, r, g, b, a, font, justify)
    SetTextFont(font or 0)
    SetTextProportional(1)
    SetTextScale(scale, scale)
    SetTextColour(r, g, b, a)
    SetTextDropShadow(0, 0, 0, 0, 255)
    SetTextEdge(2, 0, 0, 0, 255)
    SetTextOutline()
    if justify == 1 then
        SetTextRightJustify(true)
        SetTextWrap(0.0, x)
    elseif justify == 2 then
        SetTextCentre(true)
    end
    BeginTextCommandDisplayText("STRING")
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayText(x, y)
end

function Utils.DrawRect2D(x, y, w, h, r, g, b, a)
    DrawRect(x + w/2, y + h/2, w, h, r, g, b, a)
end

---------------------------------------------------
-- 3D Drawing (world space)
---------------------------------------------------

-- Draw a thick 3D line between two points with color
function Utils.DrawLine3D(p1, p2, r, g, b, a)
    DrawLine(p1.x, p1.y, p1.z, p2.x, p2.y, p2.z, r, g, b, a)
end

-- Draw a vertical pillar marker at a world position (like a checkpoint pole)
function Utils.DrawPillar(pos, r, g, b, a)
    -- Type 27 = vertical cylinder / pillar
    DrawMarker(27, pos.x, pos.y, pos.z, 0,0,0, 0,0,0, 0.3, 0.3, 3.0, r, g, b, a, false, false, 2, false, nil, nil, false)
end

-- Draw a flat checkered-flag style marker on the ground
function Utils.DrawGroundMarker(pos, r, g, b, a, scale)
    scale = scale or 2.0
    -- Type 4 = flat circle going up
    DrawMarker(4, pos.x, pos.y, pos.z - 0.5, 0,0,0, 0,0,0, scale, scale, 1.0, r, g, b, a, false, false, 2, false, nil, nil, false)
end

-- Draw a full start/finish line with pillars at A and B and a line connecting them
function Utils.DrawTrackLine(p1, p2, r, g, b, a)
    -- Draw the line itself
    Utils.DrawLine3D(p1, p2, r, g, b, a)
    -- Draw pillars at each end
    Utils.DrawPillar(p1, r, g, b, a)
    Utils.DrawPillar(p2, r, g, b, a)
end

-- Draw a small floating arrow/cone marker above a position (for placement preview)
function Utils.DrawPlacementPreview(pos, r, g, b, a)
    -- Type 2 = inverted cone (downward arrow)
    DrawMarker(2, pos.x, pos.y, pos.z + 2.0, 0,0,0, 180.0,0,0, 0.4, 0.4, 0.6, r, g, b, a, true, false, 2, false, nil, nil, false)
    -- Type 28 = flat ring on ground
    DrawMarker(28, pos.x, pos.y, pos.z - 0.5, 0,0,0, 0,0,0, 1.5, 1.5, 0.5, r, g, b, 120, false, false, 2, false, nil, nil, false)
end

---------------------------------------------------
-- Line crossing detection (2D cross product)
---------------------------------------------------
function Utils.GetSideOfLine(p, a, b)
    return (p.x - a.x) * (b.y - a.y) - (p.y - a.y) * (b.x - a.x)
end

-- Returns true when pos crosses the line defined by a-b compared to previous position
function Utils.HasCrossedLine(prevPos, currPos, lineA, lineB)
    local side1 = Utils.GetSideOfLine(prevPos, lineA, lineB)
    local side2 = Utils.GetSideOfLine(currPos, lineA, lineB)
    if (side1 * side2) < 0 then
        -- Crossed! Check if close enough to the line segment
        local midpoint = (lineA + lineB) / 2.0
        local lineLen = Utils.Distance(lineA, lineB)
        local distToMid = Utils.Distance(vector3(currPos.x, currPos.y, currPos.z), vector3(midpoint.x, midpoint.y, midpoint.z))
        return distToMid < (lineLen * 1.5)
    end
    return false
end

---------------------------------------------------
-- Notifications
---------------------------------------------------
function Utils.ShowNotification(text)
    SetNotificationTextEntry("STRING")
    AddTextComponentSubstringPlayerName(text)
    DrawNotification(false, false)
end

function Utils.ShowHelpText(text)
    BeginTextCommandDisplayHelp("STRING")
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayHelp(0, false, true, -1)
end

---------------------------------------------------
-- Keyboard input (on-screen keyboard)
---------------------------------------------------
function Utils.GetKeyboardInput(title, defaultText, maxLength)
    AddTextEntry("CIDADE_GHOST_INPUT", title)
    DisplayOnscreenKeyboard(1, "CIDADE_GHOST_INPUT", "", defaultText or "", "", "", "", maxLength or 30)
    while UpdateOnscreenKeyboard() == 0 do
        Wait(0)
    end
    if GetOnscreenKeyboardResult() then
        return GetOnscreenKeyboardResult()
    end
    return nil
end

---------------------------------------------------
-- Blips
---------------------------------------------------
function Utils.CreateBlipAt(pos, sprite, color, label)
    local blip = AddBlipForCoord(pos.x, pos.y, pos.z)
    SetBlipSprite(blip, sprite or 1)
    SetBlipColour(blip, color or 2)
    SetBlipScale(blip, 0.8)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentSubstringPlayerName(label or "Ponto")
    EndTextCommandSetBlipName(blip)
    return blip
end

---------------------------------------------------
-- Ped Appearance & Anim Helpers
---------------------------------------------------
local commonAnims = {
    { dict = "amb@world_human_smoking@male@male_a@idle_a", name = "idle_a" },
    { dict = "cellphone@", name = "cellphone_text_read_base" },
    { dict = "cellphone@", name = "cellphone_call_listen_base" },
    { dict = "amb@code_human_in_car_mp_actions@smoke@std@ds@base", name = "smoke_a" },
    { dict = "amb@code_human_in_car_mp_actions@drink@std@ds@base", name = "drink_a" },
    { dict = "amb@code_human_in_car_mp_actions@dance@std@ds@base", name = "dance_a" },
    { dict = "amb@code_human_in_car_mp_actions@waving@std@rds@base", name = "waving_a" }
}

function Utils.GetCurrentPedAnim(ped)
    for _, anim in ipairs(commonAnims) do
        if IsEntityPlayingAnim(ped, anim.dict, anim.name, 3) then
            return anim
        end
    end
    return nil
end

function Utils.GetPedAppearance(ped)
    local appearance = {
        model = GetEntityModel(ped),
        components = {},
        props = {}
    }
    
    for i = 0, 11 do
        appearance.components[tostring(i)] = {
            drawable = GetPedDrawableVariation(ped, i),
            texture = GetPedTextureVariation(ped, i),
            palette = GetPedPaletteVariation(ped, i)
        }
    end
    
    for i = 0, 7 do
        appearance.props[tostring(i)] = {
            drawable = GetPedPropIndex(ped, i),
            texture = GetPedPropTextureIndex(ped, i)
        }
    end
    
    return appearance
end

function Utils.SetPedAppearance(ped, appearance)
    if not appearance then return end
    
    -- Apply components
    if appearance.components then
        for k, v in pairs(appearance.components) do
            local compId = tonumber(k)
            SetPedComponentVariation(ped, compId, v.drawable, v.texture, v.palette or 0)
        end
    end
    
    -- Apply props
    if appearance.props then
        for k, v in pairs(appearance.props) do
            local propId = tonumber(k)
            if v.drawable == -1 then
                ClearPedProp(ped, propId)
            else
                SetPedPropIndex(ped, propId, v.drawable, v.texture, true)
            end
        end
    end
end


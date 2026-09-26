-- BODYCAM 1.0.0 | Brouken
_G.BODYCAM = _G.BODYCAM or {}
local BC = BODYCAM
if BC.settings_loaded then return end
BC.settings_loaded = true
BC.enabled = true
BC.mode = 2 -- Approved Wrist profile.
BC.key = "f8"
BC.save_path = (SavePath or BLTModManager.Constants:SavesDirectory()) .. "bodycam_settings.json"

local file = io.open(BC.save_path, "r")
if file then
    local content = file:read("*all")
    file:close()
    local ok, settings = pcall(json.decode, content)
    if ok and type(settings) == "table" then
        if type(settings.enabled) == "boolean" then BC.enabled = settings.enabled end
        if type(settings.key) == "string" then BC.key = settings.key end
    else
        log("[BODYCAM] Settings could not be read; using defaults.")
    end
end
BC.view_mode = BC.enabled and 6 or 3

function BC:save_settings()
    local file = io.open(self.save_path, "w")
    if not file then
        log("[BODYCAM] Could not save settings; this session's mode is still active.")
        return false
    end
    local written = file:write(json.encode({enabled=self.enabled, key=self.key}))
    local closed = file:close()
    if not written or not closed then
        log("[BODYCAM] Could not finish saving settings.")
        return false
    end
    return true
end

function BC:set_enabled(enabled)
    self.enabled = enabled == true
    self.mode = 2
    self.view_mode = self.enabled and 6 or 3
    if _G.BODYCAM_FREEAIM_TUNING then BODYCAM_FREEAIM_TUNING.enabled = self.enabled end

    -- Remove the old pose before native stance updates can copy it. The next
    -- camera update builds either the native pose or the approved Bodycam pose.
    local camera = self.runtime and self.runtime.camera
    if camera and alive(camera._unit) then
        self:remove_shoulder_offset(camera._shoulder_stance)
        self:restore_vanilla_overshot(camera._vel_overshot)
        local properties = camera._camera_properties
        if properties and camera._bodycam_tracking_yaw then
            properties.spin = (properties.spin - camera._bodycam_tracking_yaw) % 360
        end
        camera._bodycam_tracking_yaw = nil
        camera._bodycam_tracking_correction = nil
        camera._bodycam_input_spin = nil
        camera._bodycam_ads_gain = nil
    end
    if _G.BODYCAM_FREEAIM and BODYCAM_FREEAIM.full_reset then BODYCAM_FREEAIM:full_reset() end
end

function BC:toggle()
    self:set_enabled(not self.enabled)
    local saved = self:save_settings()
    local message = "BODYCAM | " .. (self.enabled and "ON" or "OFF")
    if not saved then message = message .. " | SETTINGS NOT SAVED" end
    log("[BODYCAM] " .. message)
    if managers and managers.hud and managers.hud.show_hint then
        managers.hud:show_hint({text=message})
    end
end

-- SuperBLT's JSON keybind registration has no default-key field. Set the
-- default through its own binding API; never replace a user's saved rebind.
-- Keep a copy because BLT omits deliberately unbound keys when saving.
local bind = BLT.Keybinds:get_keybind("bodycam_mode")
if bind then
    if bind:Key() == nil then bind:SetKey(BC.key) end
    BC.key = bind:Key()
    BC:save_settings()
end
Hooks:Add("CustomizeControllerOnKeySet", "BODYCAM_SaveKey", function(id, button)
    if id == "bodycam_mode" and type(button) == "string" then
        BC.key = button
        BC:save_settings()
    end
end)
log("[BODYCAM] 1.0.0 | Brouken | " .. (BC.enabled and "ON" or "OFF"))

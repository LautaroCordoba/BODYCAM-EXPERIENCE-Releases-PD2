if not FPCameraPlayerBase then
    return
end

-- Author: Brouken

_G.BODYCAM =
    _G.BODYCAM or {}

local BC =
    _G.BODYCAM

BC.mode =
    BC.mode or 2

-- Keep the loaded mode across camera initialization.
if BC.view_mode ~= 3 then BC.view_mode = 6 end

BC.base_path =
    ModPath or "mods/BODYCAM/"

BC.runtime =
    BC.runtime or {}

local RT =
    BC.runtime

RT.last_yaw =
    RT.last_yaw or 0

RT.last_pitch =
    RT.last_pitch or 0

RT.last_center_x =
    RT.last_center_x or 0

RT.last_center_y =
    RT.last_center_y or 0

RT.last_center_z =
    RT.last_center_z or 0

RT.shoulder_applied =
    false

local function clamp(
    value,
    minimum,
    maximum
)

    if value < minimum then
        return minimum
    end

    if value > maximum then
        return maximum
    end

    return value

end

local function safe_number(
    value,
    fallback
)

    if type(value) == "number"
    and value == value
    and value ~= math.huge
    and value ~= -math.huge then

        return value

    end

    return fallback or 0

end

-- PAYDAY Vector3 exposes numeric x/y/z properties here.
-- vector:x()
-- vector:y()
-- vector:z()

local function copy_vector(vector)

    if not vector then
        return nil
    end

    return Vector3(
        safe_number(
            vector.x,
            0
        ),

        safe_number(
            vector.y,
            0
        ),

        safe_number(
            vector.z,
            0
        )
    )

end

function BC:notify(text, hud_text)

    log(
        "[BODYCAM] "
        .. tostring(text)
    )

    if managers
    and managers.hud
    and managers.hud.show_hint then

        managers.hud:show_hint({
            text =
                hud_text or ("BODYCAM | " .. tostring(text))
        })

    end

end

local function validate_tuning(modes, config)
    if type(modes) ~= "table" or next(modes) == nil then
        return false, "a non-empty profile list is required"
    end

    local count = 0
    for index in pairs(modes) do
        if type(index) ~= "number" or index < 1 or index % 1 ~= 0 then
            return false, "profiles must use consecutive indices starting at 1"
        end
        count = count + 1
    end

    -- Missing fields retain the existing runtime defaults. Signed inertia and
    -- offsets remain available; only limits required by the math are enforced.
    local fields = {
        {"max_yaw", 0}, {"max_pitch", 0}, {"sensitivity"},
        {"shoulder_yaw", 0}, {"shoulder_pitch", 0},
        {"soft_start", 0, 1}, {"edge_multiplier", 0, 1},
        {"inertia_yaw"}, {"inertia_pitch"},
        {"pivot_x"}, {"pivot_y"}, {"pivot_z"},
        {"center_x"}, {"center_y"}, {"center_z"}, {"hip_center_x"}, {"hip_center_y"}, {"hip_center_z"},
        {"experimental_hip_pitch", -10, 10}, {"hip_freeaim_pivot_y", 0, 50},
        {"hip_recenter_speed", 0, 10}, {"hip_recenter_delay", 0, 2},
        {"hip_follow_rate", 0, 10}, {"hip_follow_margin", 0, 20},
        {"ads_follow_rate", 0, 10}, {"ads_follow_margin", 0, 20}
    }

    for index = 1, count do
        local profile = modes[index]
        if type(profile) ~= "table" then
            return false, "profile " .. index .. " missing or invalid"
        end
        if type(profile.name) ~= "string" or not profile.name:find("%S") then
            return false, "profile " .. index .. ": name must be non-empty text"
        end
        if profile.use_vanilla_inertia ~= nil and type(profile.use_vanilla_inertia) ~= "boolean" then
            return false, "profile " .. index .. ": use_vanilla_inertia must be true or false"
        end
        for _, field in ipairs(fields) do
            local key, minimum, maximum = field[1], field[2], field[3]
            if profile[key] ~= nil then
                local value = tonumber(profile[key])
                if not value or value ~= value or value == math.huge or value == -math.huge
                    or (minimum and value < minimum) or (maximum and value > maximum) then
                    return false, "profile " .. index .. " (" .. profile.name .. "): " .. key .. " invalid"
                end
            end
        end
    end

    if type(config) ~= "table" or type(config.enabled) ~= "boolean" then
        return false, "FREEAIM_TUNING.enabled must be true or false"
    end
    return true
end

function BC:load_tuning()

    local path =
        self.base_path
        .. "config/tuning.lua"

    local file =
        io.open(
            path,
            "r"
        )

    if not file then

        self:notify(
            "TUNING REJECTED: config/tuning.lua not found; unchanged"
        )

        return false

    end

    file:close()

    local previous_modes = _G.BODYCAM_TUNING
    local previous_config = _G.BODYCAM_FREEAIM_TUNING

    -- tuning.lua updates enabled in place. Stage a copy so a failed reload
    -- cannot change the live ON/OFF state before validation has succeeded.
    _G.BODYCAM_FREEAIM_TUNING = {}
    for key, value in pairs(previous_config or {}) do
        _G.BODYCAM_FREEAIM_TUNING[key] = value
    end

    _G.BODYCAM_TUNING =
        nil

    local ok, err =
        pcall(
            dofile,
            path
        )

    if ok then
        ok, err = validate_tuning(_G.BODYCAM_TUNING, _G.BODYCAM_FREEAIM_TUNING)
    end

    if not ok then

        _G.BODYCAM_TUNING = previous_modes
        _G.BODYCAM_FREEAIM_TUNING = previous_config

        self:notify(
            "TUNING REJECTED: " .. tostring(err) .. "; unchanged"
        )

        return false

    end

    self.modes =
        _G.BODYCAM_TUNING

    if self.mode > #self.modes then

        self.mode =
            1

    end

    return true

end

function BC:show_mode(message)

    if not self.modes then
        return
    end

    local profile =
        self.modes[
            self.mode
        ]

    if not profile then
        return
    end

    self:notify(
        (message and message .. " | " or "")
        .. "Profile "
        .. tostring(self.mode)
        .. "/"
        .. tostring(#self.modes)
        .. " | "
        .. tostring(profile.name),
        "BODYCAM | INERTIA | " .. tostring(profile.name)
    )

end

function BC:remove_shoulder_offset(
    shoulder
)

    if not RT.shoulder_applied then
        return
    end

    if shoulder == RT.shoulder_owner
    and shoulder
    and shoulder.rotation then

        local previous_rotation =
            Rotation(
                RT.last_yaw,
                RT.last_pitch,
                0
            )

        shoulder.rotation = RT.last_base_rotation or
            (shoulder.rotation * previous_rotation:inverse())

        -- Hip orientation was applied BEFORE FreeAim; undo in reverse order.
        if RT.last_hip_pitch and RT.last_hip_pitch ~= 0 then
            shoulder.rotation = shoulder.rotation * Rotation(0, RT.last_hip_pitch, 0):inverse()
        end

    end

    if shoulder == RT.shoulder_owner
    and shoulder
    and shoulder.translation then

        shoulder.translation =
            shoulder.translation
            -
            Vector3(
                RT.last_center_x,
                RT.last_center_y,
                RT.last_center_z
            )

    end

    RT.last_yaw =
        0

    RT.last_pitch =
        0

    RT.last_center_x =
        0

    RT.last_center_y =
        0

    RT.last_center_z =
        0

    RT.shoulder_applied =
        false

    RT.shoulder_owner = nil
    RT.last_hip_pitch = 0
    RT.last_base_rotation = nil

end

-- Both primary and canted sights are ADS. Native absolute_progress instead
-- tracks the primary sight model swap, so canted transitions need their own start.
local function ads_weight(shoulder, t)
    local target = shoulder.in_steelsight and 1 or 0
    local tr = shoulder.transition
    if tr and t and tr.start_t and tr.duration and tr.duration > 0 then
        local start = tr._bodycam_ads_start
        if start == nil then start = tr.absolute_progress end
        if start ~= nil then
            local p = clamp((t - tr.start_t) / tr.duration, 0, 1)
            p = p * p * (3 - 2 * p)
            return start + (target - start) * p
        end
    end
    return target
end

-- Hip motion uses the weapon frame; ADS input must use camera axes even
-- when the native stance rolls the weapon to a canted sight.
local function aim_rotation(base, yaw, pitch, ads)
    local aim = Rotation(yaw, pitch, 0)
    local hip = base * aim
    if ads <= 0 then return hip end
    local sight = aim * base
    if ads >= 1 then return sight end
    return hip:slerp(sight, ads)
end

-- Native stance transitions overwrite the shoulder, including their final
-- frame. Remove our contribution BEFORE that write, not from the new base.
Hooks:PreHook(
    FPCameraPlayerBase,
    "_update_stance",
    "BODYCAM_ShoulderBeforeStanceUpdate",
    function(self)
        if self._shoulder_stance and self._shoulder_stance.transition then
            BC:remove_shoulder_offset(self._shoulder_stance)
        end
    end
)

-- The game copies the current shoulder into the transition's start values.
-- Keep BODYCAM out of that copy so it cannot become part of the native base.
Hooks:PreHook(
    FPCameraPlayerBase,
    "clbk_stance_entered",
    "BODYCAM_ShoulderBeforeStanceCapture",
    function(self, new_shoulder_stance)
        self._bodycam_previous_ads = nil
        if new_shoulder_stance then
            local s = self._shoulder_stance
            if s then
                self._bodycam_previous_ads = {
                    in_steelsight = s.in_steelsight,
                    in_second_sight = s.in_second_sight,
                    transition = s.transition
                }
            end
            BC:remove_shoulder_offset(s)
        end
    end
)

Hooks:PreHook(
    FPCameraPlayerBase,
    "set_stance_instant",
    "BODYCAM_ShoulderBeforeInstantStance",
    function(self, stance_name)
        local stance = tweak_data.player.stances.default[stance_name]
        if stance and stance.shoulders then
            BC:remove_shoulder_offset(self._shoulder_stance)
        end
    end
)

function BC:capture_vanilla_overshot(
    overshot,
    source
)

    if not overshot then
        return
    end

    if overshot._bodycam_applied and not source then
        return
    end

    -- A transition may start from BODYCAM values. Save its native
    -- destination, never an intermediate blend, for later restoration.
    local transition = overshot.transition

    if not source and transition then
        source = {
            yaw_neg = transition.end_yaw_neg,
            yaw_pos = transition.end_yaw_pos,
            pitch_neg = transition.end_pitch_neg,
            pitch_pos = transition.end_pitch_pos,
            pivot = transition.end_pivot
        }
    end

    source = source or overshot

    -- Keep the snapshot with its owner, not across camera instances.
    overshot._bodycam_vanilla = {

        yaw_neg =
            source.yaw_neg,

        yaw_pos =
            source.yaw_pos,

        pitch_neg =
            source.pitch_neg,

        pitch_pos =
            source.pitch_pos,

        pivot =
            copy_vector(
                source.pivot
            )

    }

end

function BC:restore_vanilla_overshot(
    overshot
)

    if not overshot or not overshot._bodycam_applied then
        return
    end

    overshot._bodycam_applied = false

    -- The game has already updated this frame's native transition.
    -- Do not replace that blend with a cached stance or cancel it.
    if overshot.transition then
        return
    end

    local vanilla =
        overshot._bodycam_vanilla

    if not vanilla then
        return
    end

    overshot.yaw_neg =
        vanilla.yaw_neg

    overshot.yaw_pos =
        vanilla.yaw_pos

    overshot.pitch_neg =
        vanilla.pitch_neg

    overshot.pitch_pos =
        vanilla.pitch_pos

    if overshot.pivot
    and vanilla.pivot then

        mvector3.set(
            overshot.pivot,
            vanilla.pivot
        )

    end

end

-- Stance changes reuse _vel_overshot; table identity alone cannot
-- detect a different weapon, ADS or crouched stance.
Hooks:PostHook(
    FPCameraPlayerBase,
    "clbk_stance_entered",
    "BODYCAM_OvershotStanceCapture",
    function(self, new_shoulder_stance, new_head_stance, new_vel_overshot)
        local previous = self._bodycam_previous_ads
        self._bodycam_previous_ads = nil
        local s = self._shoulder_stance
        if previous and s and s.transition and (previous.in_second_sight or s.in_second_sight
        or (previous.transition and previous.transition._bodycam_ads_start ~= nil)) then
            s.transition._bodycam_ads_start = ads_weight(previous, s.transition.start_t)
        end
        if new_vel_overshot then
            BC:capture_vanilla_overshot(self._vel_overshot, new_vel_overshot)
        end
    end
)

Hooks:PostHook(
    FPCameraPlayerBase,
    "set_stance_instant",
    "BODYCAM_OvershotInstantCapture",
    function(self, stance_name)
        local stance = tweak_data.player.stances.default[stance_name]
        if stance and stance.vel_overshot then
            BC:capture_vanilla_overshot(self._vel_overshot, self._vel_overshot)
        end
    end
)

function BC:next_view()
    self.view_mode = self.view_mode == 6 and 3 or 6
    -- Compare from neutral rather than carrying a hidden aim offset into view.
    if _G.BODYCAM_FREEAIM and BODYCAM_FREEAIM.full_reset then
        BODYCAM_FREEAIM:full_reset()
    end
    local names = {[3]="Vanilla", [6]="Bodycam"}
    self:notify(
        "View comparison: " .. names[self.view_mode]
        .. (self.view_mode == 3 and " | Bodycam view suspended; profile retained" or " | FreeAim reset for comparison"),
        "BODYCAM | VIEW | " .. names[self.view_mode]
    )
end

function BC:next_mode()

    if not self:load_tuning() then
        return
    end

    if not self.modes
    or #self.modes == 0 then
        return
    end

    self.mode =
        self.mode + 1

    if self.mode > #self.modes then

        self.mode =
            1

    end

    if _G.BODYCAM_FREEAIM
    and BODYCAM_FREEAIM.full_reset then

        BODYCAM_FREEAIM:full_reset()

    end

    self:show_mode("Tuning reloaded and validated")

end

BC:load_tuning()
if BC.enabled ~= nil and _G.BODYCAM_FREEAIM_TUNING then
    BODYCAM_FREEAIM_TUNING.enabled = BC.enabled
end

log("[BODYCAM] Pose control and inertia restoration loaded.")

local initialized =
    false

Hooks:PostHook(
    FPCameraPlayerBase,
    "update",
    "BODYCAM_V0122_StableCamera",

    function(self, unit, t, dt)

        RT.camera = self

        -- Sample native look before adding our transfer; store the final spin
        -- below so automatic following cannot be mistaken for mouse motion.
        local spin = self._camera_properties and self._camera_properties.spin
        local previous_spin = self._bodycam_input_spin
        self._bodycam_input_spin = spin
        local ads_gain = self._bodycam_ads_gain or .5
        self._bodycam_ads_gain = nil

        if not BC.modes then
            return
        end

        local profile =
            BC.modes[
                BC.mode
            ]

        if not profile then
            return
        end

        local shoulder =
            self._shoulder_stance

        BC:remove_shoulder_offset(
            shoulder
        )

        -- Native viewmodel for comparison; the selected preset/config survive.
        if BC.enabled == false or BC.view_mode == 3 then
            BC:restore_vanilla_overshot(self._vel_overshot)
            return
        end

        local cfg =
            _G.BODYCAM_FREEAIM_TUNING

        -- INERTIA IS SELECTED BY THE PRESET, INDEPENDENTLY OF FREE AIM

        if profile.use_vanilla_inertia then

            -- Restore PAYDAY movement.

            if self._vel_overshot then

                BC:restore_vanilla_overshot(
                    self._vel_overshot
                )

            end

        elseif self._vel_overshot then

            -- Capture vanilla BEFORE BODYCAM writes.

            BC:capture_vanilla_overshot(
                self._vel_overshot
            )

            local inertia_yaw =
                tonumber(
                    profile.inertia_yaw
                )
                or 0

            local inertia_pitch =
                tonumber(
                    profile.inertia_pitch
                )
                or 0

            self._vel_overshot.yaw_neg =
                inertia_yaw

            self._vel_overshot.yaw_pos =
                -inertia_yaw

            self._vel_overshot.pitch_neg =
                -inertia_pitch

            self._vel_overshot.pitch_pos =
                inertia_pitch

            if self._vel_overshot.pivot then

                mvector3.set(
                    self._vel_overshot.pivot,

                    Vector3(
                        tonumber(
                            profile.pivot_x
                        )
                        or 0,

                        tonumber(
                            profile.pivot_y
                        )
                        or 0,

                        tonumber(
                            profile.pivot_z
                        )
                        or 0
                    )
                )

            end

            self._vel_overshot._bodycam_applied =
                true

        end

        -- HIP POSITION: independent of FreeAim, fading with native ADS.

        local hip_center_x = 0
        local hip_center_y = 0
        local hip_center_z = 0
        local hip_weight = 0
        if shoulder and shoulder.translation then
            local ads = ads_weight(shoulder, t)
            hip_weight = 1 - ads
            hip_center_x = (tonumber(profile.hip_center_x) or 0) * (1 - ads)
            hip_center_y = (tonumber(profile.hip_center_y) or 0) * (1 - ads)
            hip_center_z = (tonumber(profile.hip_center_z) or 0) * (1 - ads)
            local hip_pitch = (BC.view_mode == 4 or BC.view_mode == 5 or BC.view_mode == 6) and (tonumber(profile.experimental_hip_pitch) or 0) * (1 - ads) or 0
            if shoulder.rotation and hip_pitch ~= 0 then
                shoulder.rotation = shoulder.rotation * Rotation(0, hip_pitch, 0)
                RT.last_hip_pitch = hip_pitch
                RT.shoulder_applied = true
                RT.shoulder_owner = shoulder
            end
            if hip_center_x ~= 0 or hip_center_y ~= 0 or hip_center_z ~= 0 then
                shoulder.translation = shoulder.translation + Vector3(hip_center_x, hip_center_y, hip_center_z)
                RT.last_center_x = hip_center_x
                RT.last_center_y = hip_center_y
                RT.last_center_z = hip_center_z
                RT.shoulder_applied = true
                RT.shoulder_owner = shoulder
            end
        end

        if not cfg or not cfg.enabled then
            return
        end

        if not shoulder
        or not shoulder.rotation then
            return
        end

        local FA =
            _G.BODYCAM_FREEAIM

        if not FA then
            return
        end

        local shoulder_yaw =
            tonumber(
                profile.shoulder_yaw
            )
            or 1

        local shoulder_pitch =
            tonumber(
                profile.shoulder_pitch
            )
            or 1

        local free_yaw =
            safe_number(
                FA.yaw,
                0
            )
            *
            shoulder_yaw

        local free_pitch =
            safe_number(
                FA.pitch,
                0
            )
            *
            shoulder_pitch

        local visual_max_yaw =
            (
                tonumber(
                    profile.max_yaw
                )
                or 15
            )
            *
            shoulder_yaw

        local visual_max_pitch =
            (
                tonumber(
                    profile.max_pitch
                )
                or 9
            )
            *
            shoulder_pitch

        free_yaw =
            clamp(
                free_yaw,
                -visual_max_yaw,
                visual_max_yaw
            )

        free_pitch =
            clamp(
                free_pitch,
                -visual_max_pitch,
                visual_max_pitch
            )

        -- CAMERA CATCH-UP: transfer excess horizontal FreeAim into native look.
        local aim_weight = BC.view_mode == 6 and (1 - hip_weight) or 0
        local rate = tonumber(profile.hip_follow_rate) or 0
        local margin = tonumber(profile.hip_follow_margin) or 3
        -- ADS trial starts after the native stance transition finishes. Its
        -- narrower margin retains some freedom; exponential easing slows near it.
        local ads_follow = BC.view_mode == 6 and shoulder.in_steelsight
        if ads_follow then
            rate = tonumber(profile.ads_follow_rate) or 0
            margin = tonumber(profile.ads_follow_margin) or 1
        end
        local properties = self._camera_properties
        local state = managers and managers.player and managers.player:current_state()
        if (BC.view_mode == 5 or BC.view_mode == 6) and rate > 0 and shoulder_yaw > 0
        and not shoulder.transition and (ads_follow or (hip_weight == 1 and not shoulder.in_steelsight))
        and not self._block_input and not self._limits and not self._animate_pitch and not _G.IS_VR
        and (state == "standard" or state == "carry")
        and properties and self._output_data and self._output_data.rotation then
            local excess = math.max(0, math.abs(free_yaw) - margin)
            local step_dt = clamp(safe_number(dt, 0), 0, .1)
            local gain = 1
            if ads_follow then
                local look = self._input and self._input.look
                local moving = look and look.x ~= 0 and previous_spin ~= nil and step_dt > 0
                local target = .5
                if moving then
                    local delta = (spin - previous_spin + 180) % 360 - 180
                    target = .5 + clamp(math.abs(delta) / dt / 90, 0, 1)
                end
                gain = ads_gain + (target - ads_gain) * (1 - math.exp(-step_dt / .06))
                -- Fade the speed bonus, keeping gentle catch-up toward the central margin.
                self._bodycam_ads_gain = gain
            end
            local transfer = math.min(excess * (1 - math.exp(-rate * gain * step_dt)), (ads_follow and 24 * gain or 10) * step_dt)
            if free_yaw < 0 then transfer = -transfer end
            if transfer ~= 0 then
                local camera_rotation = self._output_data.rotation
                local head = self._head_stance and self._head_stance.rotation or Rotation(0,0,0)
                local next_camera = head * Rotation(transfer,0,0) * head:inverse() * camera_rotation
                local before = camera_rotation * aim_rotation(shoulder.rotation, free_yaw, free_pitch, aim_weight)
                free_yaw = free_yaw - transfer
                local after = next_camera * aim_rotation(shoulder.rotation, free_yaw, free_pitch, aim_weight)
                -- The next native frame applies both changes together. Exclude
                -- their model-space contribution from FreeAim's input sample.
                self._bodycam_tracking_correction = before * after:inverse()
                self._bodycam_tracking_yaw = transfer
                properties.spin = (properties.spin + transfer) % 360
                self._bodycam_input_spin = properties.spin
                FA.yaw = free_yaw / shoulder_yaw
            end
        end

        local center_x =
            tonumber(
                profile.center_x
            )
            or 0

        local center_y =
            tonumber(
                profile.center_y
            )
            or 0

        local center_z =
            tonumber(
                profile.center_z
            )
            or 0

        local pivot_offset
        if free_yaw ~= 0
        or free_pitch ~= 0 then

            local before_rotation = shoulder.rotation
            shoulder.rotation = aim_rotation(before_rotation, free_yaw, free_pitch, aim_weight)
            -- Save the clean orientation for exact removal in either basis; repeated
            -- inverse/multiply reconstruction would accumulate numerical drift.
            RT.last_base_rotation = before_rotation

            local pivot_y = tonumber(profile.hip_freeaim_pivot_y) or 0
            if (BC.view_mode == 4 or BC.view_mode == 5 or BC.view_mode == 6) and hip_weight > 0 and pivot_y ~= 0 and shoulder.translation then
                -- Rotate about p instead of the model origin: offset = R*p - R'*p.
                -- Recover the animated weapon attachment in model space so the
                -- grip stays at its resting location under FreeAim rotation.
                -- Keep the old approximate support if the attachment is absent.
                local support = Vector3(0, pivot_y, 0)
                if self._weap_align and self._unit then
                    support = self._weap_align:position() - self._unit:position()
                    mvector3.rotate_with(support, self._unit:rotation():inverse())
                end
                -- Native overshot rotates the model after shoulder rotation.
                if self._vel_overshot and self._vel_overshot.rotation then
                    mvector3.rotate_with(support, self._vel_overshot.rotation)
                end
                -- Fade back to the existing ADS behavior.
                local before = Vector3(support.x * hip_weight, support.y * hip_weight, support.z * hip_weight)
                local after = copy_vector(before)
                mvector3.rotate_with(before, before_rotation)
                mvector3.rotate_with(after, shoulder.rotation)
                pivot_offset = before - after
            end

            if BC.view_mode == 6 and hip_weight < 1 and shoulder.translation then
                -- In ADS rotate the native sight line about the camera origin:
                -- rotating orientation alone leaves its translated origin behind.
                -- Blend with the same native stance weight used by hip support.
                local aligned = copy_vector(shoulder.translation)
                mvector3.rotate_with(aligned, before_rotation:inverse())
                mvector3.rotate_with(aligned, shoulder.rotation)
                local delta = aligned - shoulder.translation
                local weight = 1 - hip_weight
                local offset = Vector3(delta.x * weight, delta.y * weight, delta.z * weight)
                pivot_offset = pivot_offset and pivot_offset + offset or offset
            end

        end

        -- Reuse the existing exact translation removal on every stance lifecycle.
        if pivot_offset then
            center_x = center_x + pivot_offset.x
            center_y = center_y + pivot_offset.y
            center_z = center_z + pivot_offset.z
        end

        if shoulder.translation
        and (
            center_x ~= 0
            or center_y ~= 0
            or center_z ~= 0
        ) then

            shoulder.translation =
                shoulder.translation
                +
                Vector3(
                    center_x,
                    center_y,
                    center_z
                )

        end

        RT.last_yaw =
            free_yaw

        RT.last_pitch =
            free_pitch

        RT.last_center_x =
            center_x + hip_center_x

        RT.last_center_y =
            center_y + hip_center_y

        RT.last_center_z =
            center_z + hip_center_z

        RT.shoulder_applied =
            true

        RT.shoulder_owner = shoulder

        if not initialized then

            initialized =
                true

            log(
                "[BODYCAM] Weapon movement active."
            )

        end

    end
)

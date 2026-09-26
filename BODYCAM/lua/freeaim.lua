if not FPCameraPlayerBase then
    return
end

-- Author: Brouken

_G.BODYCAM_FREEAIM =
    _G.BODYCAM_FREEAIM or {}

local FA =
    _G.BODYCAM_FREEAIM

FA.yaw =
    FA.yaw or 0

FA.pitch =
    FA.pitch or 0

FA.amount =
    FA.amount or 0

FA.last_camera_yaw =
    nil

FA.last_camera_pitch =
    nil

FA.last_weapon_key =
    nil

FA.initialized =
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

local function smoothstep(value)

    value =
        clamp(
            value,
            0,
            1
        )

    return
        value
        * value
        * (3 - 2 * value)

end

local function angle_delta(
    current,
    previous
)

    local delta =
        current - previous

    while delta > 180 do

        delta =
            delta - 360

    end

    while delta < -180 do

        delta =
            delta + 360

    end

    return delta

end

local function valid_number(value)

    if type(value) ~= "number" then
        return false
    end

    if value ~= value then
        return false
    end

    if value == math.huge
    or value == -math.huge then
        return false
    end

    return true

end

local function get_weapon_key()

    if not managers
    or not managers.player then
        return nil
    end

    local player =
        managers.player:player_unit()

    if not player
    or not alive(player) then
        return nil
    end

    local inventory =
        player:inventory()

    if not inventory then
        return nil
    end

    local weapon =
        inventory:equipped_unit()

    if not weapon
    or not alive(weapon) then
        return nil
    end

    return tostring(
        weapon:key()
    )

end

function FA:reset_tracking()

    self.idle_time = 0
    self.native_sight_tracking = nil
    self.last_camera_yaw =
        nil

    self.last_camera_pitch =
        nil

end

function FA:reset_position()

    self.yaw =
        0

    self.pitch =
        0

    self.amount =
        0

    self:reset_tracking()

end

function FA:full_reset()

    self:reset_position()

    self.last_weapon_key =
        get_weapon_key()

end

function FA:sanitize(profile)

    local max_yaw =
        tonumber(
            profile.max_yaw
        )
        or 15

    local max_pitch =
        tonumber(
            profile.max_pitch
        )
        or 9

    if not valid_number(
        self.yaw
    ) then

        log(
            "[BODYCAM] FreeAim: invalid yaw; reset to zero."
        )

        self.yaw =
            0

    end

    if not valid_number(
        self.pitch
    ) then

        log(
            "[BODYCAM] FreeAim: invalid pitch; reset to zero."
        )

        self.pitch =
            0

    end

    self.yaw =
        clamp(
            self.yaw,
            -max_yaw,
            max_yaw
        )

    self.pitch =
        clamp(
            self.pitch,
            -max_pitch,
            max_pitch
        )

end

function FA:edge_weight(
    current,
    maximum,
    movement,
    profile
)

    if maximum <= 0 then
        return 1
    end

    if current > 0
    and movement < 0 then

        return 1

    end

    if current < 0
    and movement > 0 then

        return 1

    end

    local amount =
        math.abs(current)
        /
        maximum

    amount =
        clamp(
            amount,
            0,
            1
        )

    local soft_start =
        tonumber(
            profile.soft_start
        )
        or 0.60

    local minimum =
        tonumber(
            profile.edge_multiplier
        )
        or 0.28

    if amount <= soft_start then

        return 1

    end

    local edge =
        (amount - soft_start)
        /
        math.max(
            1 - soft_start,
            0.001
        )

    edge =
        smoothstep(
            edge
        )

    return
        1
        -
        edge
        * (1 - minimum)

end

log("[BODYCAM] FreeAim loaded; camera movement remains unrestricted.")

Hooks:PostHook(
    FPCameraPlayerBase,
    "update",
    "BODYCAM_V0122_StableFreeAim",

    function(self, unit, t, dt)

        local tracking_correction = self._bodycam_tracking_correction
        self._bodycam_tracking_correction = nil
        local tracking_yaw = self._bodycam_tracking_yaw or 0
        self._bodycam_tracking_yaw = nil

        local BC =
            _G.BODYCAM

        if not BC
        or not BC.modes then
            return
        end

        local profile =
            BC.modes[
                BC.mode
            ]

        if not profile then
            return
        end

        FA:sanitize(
            profile
        )

        local cfg =
            _G.BODYCAM_FREEAIM_TUNING

        if not cfg
        or not cfg.enabled
        or BC.enabled == false
        or BC.view_mode == 3 then

            FA:reset_tracking()

            return

        end

        local weapon_key =
            get_weapon_key()

        if weapon_key
        and FA.last_weapon_key
        and weapon_key ~= FA.last_weapon_key then

            FA:reset_position()

        end

        FA.last_weapon_key =
            weapon_key

        if not self._unit
        or not alive(self._unit) then

            FA:reset_tracking()

            return

        end

        local rotation =
            self._unit:rotation()

        if not rotation then

            FA:reset_tracking()

            return

        end

        local current_yaw =
            rotation:yaw()

        local current_pitch =
            rotation:pitch()

        -- A rolled weapon's Euler angles mix camera pitch into model yaw.
        -- For canted ADS, sample native look axes before weapon/overshot rotation.
        local shoulder = self._shoulder_stance
        local properties = self._camera_properties
        local native_tracking = not not (BC.view_mode == 6 and shoulder
            and shoulder.in_steelsight and shoulder.in_second_sight and properties
            and valid_number(properties.spin) and valid_number(properties.pitch))
        if FA.native_sight_tracking ~= native_tracking then
            FA:reset_tracking()
            FA.native_sight_tracking = native_tracking
        end
        if native_tracking then
            current_yaw, current_pitch = properties.spin, properties.pitch
        end

        if not valid_number(
            current_yaw
        )
        or not valid_number(
            current_pitch
        ) then

            FA:reset_tracking()

            return

        end

        if FA.last_camera_yaw == nil
        or FA.last_camera_pitch == nil then

            FA.last_camera_yaw =
                current_yaw

            FA.last_camera_pitch =
                current_pitch

            return

        end

        local tracking_rotation = tracking_correction and (tracking_correction * rotation) or rotation
        local dyaw =
            angle_delta(
                tracking_rotation:yaw(),
                FA.last_camera_yaw
            )

        local dpitch =
            angle_delta(
                tracking_rotation:pitch(),
                FA.last_camera_pitch
            )

        if native_tracking then
            -- Camera catch-up is injected after this sample, not player input.
            dyaw = angle_delta(current_yaw - tracking_yaw, FA.last_camera_yaw)
            dpitch = angle_delta(current_pitch, FA.last_camera_pitch)
        end

        FA.last_camera_yaw =
            current_yaw

        FA.last_camera_pitch =
            current_pitch

        if not valid_number(
            dyaw
        )
        or not valid_number(
            dpitch
        ) then

            FA:reset_tracking()

            return

        end

        local sensitivity =
            tonumber(
                profile.sensitivity
            )
            or 0.25

        local max_yaw =
            tonumber(
                profile.max_yaw
            )
            or 15

        local max_pitch =
            tonumber(
                profile.max_pitch
            )
            or 9

        local yaw_weight =
            FA:edge_weight(
                FA.yaw,
                max_yaw,
                dyaw,
                profile
            )

        local pitch_weight =
            FA:edge_weight(
                FA.pitch,
                max_pitch,
                dpitch,
                profile
            )

        FA.yaw =
            FA.yaw
            +
            dyaw
            * sensitivity
            * yaw_weight

        FA.pitch =
            FA.pitch
            +
            dpitch
            * sensitivity
            * pitch_weight

        FA.yaw =
            clamp(
                FA.yaw,
                -max_yaw,
                max_yaw
            )

        FA.pitch =
            clamp(
                FA.pitch,
                -max_pitch,
                max_pitch
            )

        FA:sanitize(
            profile
        )

        -- Use actual look input: the animated model also moves while returning
        -- and its rotation delta must not restart the idle timer.
        local look = self._input and self._input.look
        local shoulder = self._shoulder_stance
        local speed = tonumber(profile.hip_recenter_speed) or 0
        if BC.view_mode == 4 and speed > 0 and look and shoulder
        and not shoulder.in_steelsight and not shoulder.transition
        and not self._block_input and not _G.IS_VR
        and look.x == 0 and look.y == 0 and valid_number(dt) and dt > 0 then
            local step = math.min(dt, .1)
            local delay = tonumber(profile.hip_recenter_delay) or .25
            local previous = FA.idle_time or 0
            FA.idle_time = previous + step
            local active_dt = math.max(0, FA.idle_time - delay) - math.max(0, previous - delay)
            local decay = math.exp(-speed * active_dt)
            FA.yaw = FA.yaw * decay
            FA.pitch = FA.pitch * decay
        else
            FA.idle_time = 0
        end

        local yaw_amount =
            math.abs(
                FA.yaw
            )
            /
            math.max(
                max_yaw,
                0.001
            )

        local pitch_amount =
            math.abs(
                FA.pitch
            )
            /
            math.max(
                max_pitch,
                0.001
            )

        FA.amount =
            clamp(
                math.max(
                    yaw_amount,
                    pitch_amount
                ),
                0,
                1
            )

        if not FA.initialized then

            FA.initialized =
                true

            log(
                "[BODYCAM] FreeAim tracking active."
            )

        end

    end
)

-- Author: Brouken

_G.BODYCAM_TUNING = {

    {
        name = "Default",
        -- Use each weapon/stance's native overshot; inertia/pivot values below
        -- are only used if this is explicitly changed to false.
        use_vanilla_inertia = true,

        max_yaw = 15,
        max_pitch = 9,

        sensitivity = 0.25,

        shoulder_yaw = 0.78,
        shoulder_pitch = 0.68,

        soft_start = 0.60,
        edge_multiplier = 0.28,

        inertia_yaw = 7,
        inertia_pitch = 5,

        pivot_x = 3,
        pivot_y = -10,
        pivot_z = -5,

        -- Hip offsets fade out in ADS; set all three to 0 for original placement.
        hip_center_x = -5.5,
        hip_center_y = -3,
        hip_center_z = -3,
        -- In the Bodycam view; fades out in ADS.
        experimental_hip_pitch = -3,
        -- In the Bodycam view; 0 restores baseline FreeAim.
        hip_freeaim_pivot_y = 20,
        -- Hip-only idle return; speed 0 keeps the previous persistent FreeAim.
        -- Bodycam: angular central margin and catch-up rate (0 disables).
        hip_follow_margin = 3,
        hip_follow_rate = 1.8,
        -- Bodycam after entering the sights; 0 disables ADS follow.
        ads_follow_margin = 1,
        ads_follow_rate = 4.8,
        hip_recenter_speed = 0,
        hip_recenter_delay = 0.25,
        center_x = 0,
        center_y = 0,
        center_z = 0
    },

    {
        name = "Wrist",
        use_vanilla_inertia = false,

        max_yaw = 16,
        max_pitch = 10,

        sensitivity = 0.25,

        shoulder_yaw = 0.88,
        shoulder_pitch = 0.64,

        soft_start = 0.66,
        edge_multiplier = 0.25,

        inertia_yaw = 17,
        inertia_pitch = 10,

        pivot_x = 3,
        pivot_y = -7,
        pivot_z = -4,

        hip_center_x = -5.5,
        hip_center_y = -3,
        hip_center_z = -3,
        experimental_hip_pitch = -3,
        hip_freeaim_pivot_y = 20,
        -- Hip-only idle return; speed 0 keeps the previous persistent FreeAim.
        -- Bodycam: angular central margin and catch-up rate (0 disables).
        hip_follow_margin = 3,
        hip_follow_rate = 1.8,
        -- Bodycam after entering the sights; 0 disables ADS follow.
        ads_follow_margin = 1,
        ads_follow_rate = 4.8,
        hip_recenter_speed = 0,
        hip_recenter_delay = 0.25,
        center_x = 0,
        center_y = 0,
        center_z = 0
    }
}

_G.BODYCAM_FREEAIM_TUNING =
    _G.BODYCAM_FREEAIM_TUNING or {}

if _G.BODYCAM_FREEAIM_TUNING.enabled == nil then

    _G.BODYCAM_FREEAIM_TUNING.enabled =
        true

end

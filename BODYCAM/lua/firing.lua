-- Read the rendered muzzle at emission, independently of movement controllers.
if not RaycastWeaponBase or RaycastWeaponBase._bodycam_fire_installed then return end

local original_fire = RaycastWeaponBase.fire
if type(original_fire) ~= "function" then return end

local function muzzle_direction(weapon)
    local bc = _G.BODYCAM
    if not bc or bc.enabled == false or bc.view_mode ~= 6 or _G.IS_VR then return end

    local player = managers.player:player_unit()
    if not alive(player) or not weapon._setup or weapon._setup.user_unit ~= player then return end
    local movement = player:movement()
    local state = movement and movement:current_state_name()
    if state ~= "standard" and state ~= "carry" then return end

    local equipped = player:inventory():equipped_unit()
    if not alive(equipped) then return end
    local base = equipped:base()
    if weapon ~= base and (not base or base._second_gun ~= weapon._unit) then return end

    -- only the verified ordinary hitscan path; add special weapons
    -- after checking their own launch geometry, rather than guessing a muzzle.
    local raycast = weapon._fire_raycast
    if raycast ~= RaycastWeaponBase._fire_raycast
        and (not NewRaycastWeaponBase or raycast ~= NewRaycastWeaponBase._fire_raycast) then return end
    if weapon:gadget_overrides_weapon_functions() then return end

    local muzzle = weapon:fire_object()
    if not alive(muzzle) then return end
    local rotation = muzzle:rotation()
    if not rotation then return end
    local direction = rotation:y()
    if not direction then return end
    local x, y, z = mvector3.x(direction), mvector3.y(direction), mvector3.z(direction)
    local length_sq = x * x + y * y + z * z
    if not (length_sq > 0.000001 and length_sq < math.huge) then return end

    -- Copy engine-owned data; never mutate camera vectors or cache between shots.
    direction = mvector3.copy(direction)
    mvector3.normalize(direction)
    return direction
end

RaycastWeaponBase._bodycam_fire_installed = true
function RaycastWeaponBase:fire(from_pos, direction, ...)
    -- Preserve origin, spread, damage, ammo, alerts and the native return values.
    -- Future wall interaction needs a separate decision about shot origin.
    return original_fire(self, from_pos, muzzle_direction(self) or direction, ...)
end

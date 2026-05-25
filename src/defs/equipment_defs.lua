--[[
    Empire Engine
    equipment_defs.lua

    One-time purchasable assets tracked per business as
    bus.equipment = { key = count }. Equipment is never consumed --
    it enables operation and contributes to the requirements checklist.
    Purchased through EquipmentMenu (E key in BusinessMenu TAB).
]]

-- ================== claude_changes_2026-05-25-1330 ==================
EQUIPMENT_DEFS = {

    -- ── laundromat ────────────────────────────────────────────────────
    washing_machine = {
        displayName  = 'Washing Machine',
        price        = 1200,
        allowedTypes = { 'laundromat' },
    },
    dryer = {
        displayName  = 'Dryer',
        price        = 1000,
        allowedTypes = { 'laundromat' },
    },
    coin_changer = {
        displayName  = 'Coin Changer',
        price        = 400,
        allowedTypes = { 'laundromat' },
    },

    -- ── retail ───────────────────────────────────────────────────────
    shelving_unit = {
        displayName  = 'Shelving Unit',
        price        = 350,
        allowedTypes = { 'retail' },
    },
    pos_terminal = {
        displayName  = 'POS Terminal',
        price        = 1200,
        allowedTypes = { 'retail' },
    },
    security_camera = {
        displayName  = 'Security Camera',
        price        = 600,
        allowedTypes = { 'retail' },
    },

    -- ── restaurant ───────────────────────────────────────────────────
    commercial_oven = {
        displayName  = 'Commercial Oven',
        price        = 8000,
        allowedTypes = { 'restaurant' },
    },
    commercial_fridge = {
        displayName  = 'Commercial Fridge',
        price        = 3500,
        allowedTypes = { 'restaurant' },
    },
    dining_table = {
        displayName  = 'Dining Table',
        price        = 600,
        allowedTypes = { 'restaurant' },
    },
    dining_chair = {
        displayName  = 'Dining Chair',
        price        = 90,
        allowedTypes = { 'restaurant' },
    },
    bar_setup = {
        displayName  = 'Bar Setup',
        price        = 12000,
        allowedTypes = { 'restaurant' },
        note         = 'Unlocks bartender hire slot',
    },
    pos_system = {
        displayName  = 'POS System',
        price        = 2500,
        allowedTypes = { 'restaurant' },
    },

    -- ── car dealer ───────────────────────────────────────────────────
    showroom_display = {
        displayName  = 'Showroom Display',
        price        = 5000,
        allowedTypes = { 'car_dealer' },
    },
    vehicle_lift = {
        displayName  = 'Vehicle Lift',
        price        = 8000,
        allowedTypes = { 'car_dealer' },
    },
    detailing_station = {
        displayName  = 'Detail Station',
        price        = 4000,
        allowedTypes = { 'car_dealer' },
    },

    -- ── casino ───────────────────────────────────────────────────────
    slot_machine = {
        displayName  = 'Slot Machine',
        price        = 15000,
        allowedTypes = { 'casino' },
    },
    card_table = {
        displayName  = 'Card Table',
        price        = 6000,
        allowedTypes = { 'casino' },
    },
    surveillance_sys = {
        displayName  = 'Surveillance System',
        price        = 35000,
        allowedTypes = { 'casino' },
        note         = 'Required for gaming license compliance',
    },
    casino_bar = {
        displayName  = 'Casino Bar Setup',
        price        = 18000,
        allowedTypes = { 'casino' },
        note         = 'Unlocks bar revenue and bartender hire slot',
    },
    vip_room = {
        displayName  = 'VIP Room',
        price        = 50000,
        allowedTypes = { 'casino' },
    },

    -- ── aerospace ────────────────────────────────────────────────────
    mfg_equipment = {
        displayName  = 'Mfg Equipment',
        price        = 500000,
        allowedTypes = { 'aerospace' },
    },
    computer_systems = {
        displayName  = 'Computer Systems',
        price        = 250000,
        allowedTypes = { 'aerospace' },
    },
    launch_facility = {
        displayName  = 'Launch Facility',
        price        = 2000000,
        allowedTypes = { 'aerospace' },
    },
    wind_tunnel = {
        displayName  = 'Wind Tunnel',
        price        = 800000,
        allowedTypes = { 'aerospace' },
    },
}
-- ====================================================================

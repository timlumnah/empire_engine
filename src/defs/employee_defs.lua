--[[
    Empire Engine
    employee_defs.lua

    Role definitions and name pool for the employee system.
    Each role: capacityBonus added to business effective capacity,
    salaryRange {min, max} per game-month, allowedTypes limits
    which business types can hire this role (nil = unrestricted).
]]

-- ================== claude_changes_2026-05-25-1228 ==================
-- ================== claude_changes_2026-05-25-1330 ==================
EMPLOYEE_ROLES = {

    -- ── general (multi-type) ──────────────────────────────────────────
    general_worker = {
        label         = 'Worker',
        capacityBonus = 60,
        salaryRange   = { 800, 1500 },
        allowedTypes  = { 'laundromat', 'retail' },
    },
    manager = {
        label         = 'Manager',
        capacityBonus = 150,
        salaryRange   = { 3000, 6000 },
        allowedTypes  = { 'laundromat', 'retail', 'restaurant' },
    },

    -- ── laundromat ────────────────────────────────────────────────────
    attendant = {
        label         = 'Attendant',
        capacityBonus = 60,
        salaryRange   = { 1200, 2200 },
        allowedTypes  = { 'laundromat' },
    },

    -- ── retail ───────────────────────────────────────────────────────
    cashier = {
        label         = 'Cashier',
        capacityBonus = 80,
        salaryRange   = { 1500, 2500 },
        allowedTypes  = { 'retail' },
    },
    floor_staff = {
        label         = 'Floor Staff',
        capacityBonus = 100,
        salaryRange   = { 1800, 3000 },
        allowedTypes  = { 'retail' },
    },

    -- ── restaurant ───────────────────────────────────────────────────
    head_chef = {
        label         = 'Head Chef',
        capacityBonus = 0,       -- hard operational requirement, not a throughput bonus
        salaryRange   = { 8000, 15000 },
        allowedTypes  = { 'restaurant' },
    },
    cook = {
        label         = 'Cook',
        capacityBonus = 200,
        salaryRange   = { 3000, 6000 },
        allowedTypes  = { 'restaurant' },
    },
    server = {
        label         = 'Server',
        capacityBonus = 80,
        salaryRange   = { 1800, 3500 },
        allowedTypes  = { 'restaurant' },
    },
    host_hostess = {
        label         = 'Host/Hostess',
        capacityBonus = 40,
        salaryRange   = { 1500, 2500 },
        allowedTypes  = { 'restaurant' },
    },
    bartender = {
        label         = 'Bartender',
        capacityBonus = 120,
        salaryRange   = { 2500, 4500 },
        allowedTypes  = { 'restaurant', 'casino' },
    },
    restaurant_manager = {
        label         = 'Restaurant Mgr',
        capacityBonus = 200,
        salaryRange   = { 5000, 9000 },
        allowedTypes  = { 'restaurant' },
    },

    -- ── car dealer ───────────────────────────────────────────────────
    salesperson = {
        label         = 'Salesperson',
        capacityBonus = 400,     -- each one moves more vehicles
        salaryRange   = { 2000, 4000 },
        allowedTypes  = { 'car_dealer' },
    },
    sales_manager = {
        label         = 'Sales Manager',
        capacityBonus = 600,
        salaryRange   = { 6000, 10000 },
        allowedTypes  = { 'car_dealer' },
    },
    finance_manager = {
        label         = 'Finance Manager',
        capacityBonus = 0,       -- unlocks financing deals, not a throughput boost
        salaryRange   = { 7000, 12000 },
        allowedTypes  = { 'car_dealer' },
    },
    general_manager = {
        label         = 'General Manager',
        capacityBonus = 300,
        salaryRange   = { 10000, 18000 },
        allowedTypes  = { 'car_dealer', 'casino' },
    },
    admin_staff = {
        label         = 'Admin Staff',
        capacityBonus = 30,
        salaryRange   = { 2000, 3500 },
        allowedTypes  = { 'car_dealer', 'aerospace' },
    },

    -- ── casino ───────────────────────────────────────────────────────
    card_dealer = {
        label         = 'Card Dealer',
        capacityBonus = 350,
        salaryRange   = { 2500, 4500 },
        allowedTypes  = { 'casino' },
    },
    pit_boss = {
        label         = 'Pit Boss',
        capacityBonus = 500,
        salaryRange   = { 5000, 9000 },
        allowedTypes  = { 'casino' },
    },
    security = {
        label         = 'Security',
        capacityBonus = 0,       -- required for gaming compliance
        salaryRange   = { 2200, 3800 },
        allowedTypes  = { 'casino', 'car_dealer' },
    },
    cocktail_waitress = {
        label         = 'Cocktail Waitress',
        capacityBonus = 100,
        salaryRange   = { 1500, 2800 },
        allowedTypes  = { 'casino' },
    },

    -- ── aerospace ────────────────────────────────────────────────────
    engineer = {
        label         = 'Engineer',
        capacityBonus = 500,
        salaryRange   = { 12000, 25000 },
        allowedTypes  = { 'aerospace' },
    },
    manufacturing_worker = {
        label         = 'Mfg Worker',
        capacityBonus = 200,
        salaryRange   = { 4000, 7000 },
        allowedTypes  = { 'aerospace' },
    },
    attorney = {
        label         = 'Attorney',
        capacityBonus = 0,       -- regulatory compliance requirement
        salaryRange   = { 15000, 30000 },
        allowedTypes  = { 'aerospace' },
    },
    executive = {
        label         = 'Executive',
        capacityBonus = 0,       -- unlocks government contracts
        salaryRange   = { 25000, 50000 },
        allowedTypes  = { 'aerospace' },
    },
}

-- random name pool for generated employees
EMPLOYEE_NAME_POOL = {
    'Alex', 'Jordan', 'Sam', 'Taylor', 'Morgan',
    'Casey', 'Riley', 'Quinn', 'Drew', 'Cameron',
    'Avery', 'Peyton', 'Logan', 'Parker', 'Blake',
    'Reese', 'Harper', 'Finley', 'Rowan', 'Sage',
    'Devon', 'Ellis', 'Jamie', 'Skyler', 'Hayden',
    'Reagan', 'Emery', 'Dallas', 'Kendall', 'Lane',
}
-- ====================================================================

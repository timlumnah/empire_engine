--[[
   Empire Engine
   Based on CS50 2D Coursework

   -- Business Types List --

   Author: Tim Lumnah
   github.com/timlumnah/empire_engine

   Static configuration table for all purchasble business types
   (laundromat, retail, restaurant, car dealer, casino, aerospace).
   Each entry defines startup cost, pricing, capacity, risk, and
   initial financial state used when a Business instance is created.
]]

-- all purchasable buisness types, keyed by type string
-- Business:init copies these fields onto self using a for loop
-- adding a new entry here and to BUSINESS_ORDER in BusinessOpenMenu is all you need
BUSINESS_TYPES = {

    -- cheapest and safest buisness, good first purchace for early game
    -- low capacity but also low risk so demand stays relatvely steady
    ['laundromat'] = {
        type = "laundromat",
        displayName = "Laundromat",
        startupCost = 7000,
        basePrice = 5,
        fixedCosts = 500,
        variableCost = 1,
        capacity = 400,
        risk = 0.1,
        -- ================== claude_changes_2026-05-25-1228 ==================
        maxEmployees = 4,
        scaleTiers = {
            { mult = 1.0, cost = 0 },
            { mult = 1.5, cost = math.floor(7000 * 0.75) },
            { mult = 2.5, cost = math.floor(7000 * 1.5) },
        },
        -- ====================================================================
        -- ================== claude_changes_2026-05-25-1330 ==================
        requirements = {
            { id='lm_washers',   type='equipment', key='washing_machine', minCount=4, label='Washing Machines', tier='required'    },
            { id='lm_dryers',    type='equipment', key='dryer',           minCount=4, label='Dryers',           tier='required'    },
            { id='lm_att1',      type='employee',  key='attendant',       minCount=1, label='Attendant',        tier='required'    },
            { id='lm_changer',   type='equipment', key='coin_changer',    minCount=2, label='Coin Changers',    tier='recommended' },
            { id='lm_att2',      type='employee',  key='attendant',       minCount=2, label='Attendants (2+)',  tier='recommended' },
            { id='lm_manager',   type='employee',  key='manager',         minCount=1, label='Manager',          tier='recommended' },
        },
        -- ====================================================================
    },

    -- mid range retail shop, higher revenue ceiling but bigger overhead
    -- retail has extra fields set explictly as an example of a more complete def
    ['retail'] = {
        type = "retail",
        displayName = "Retail",
        startupCost = 10000,
        basePrice = 50,
        fixedCosts = 3000,
        unitWholeSaleCost = 4,
        capacity = 1000,
        risk = 0.2,
        startingCash = 2000,
        startingReputation = 0.8,
        marketMultiplier = 1.0,
        employees = {},
        products = {},
        services = {},
        transactions = {},
        animations = {},
        callbacks = {},
        trackingMetrics = {
            LifeTimeUnitsSold = 0,
            LifeTimeRevenue = 0,
            fixedCostsPerSecond = 0,
            revenueLastFrame = 0,
            profitLastFrame = 0,
            costsLastFrame = 0,
            unitsSoldLastFrame = 0,
        },
        -- ================== claude_changes_2026-05-25-1228 ==================
        maxEmployees = 8,
        stockLevel = 0,         -- units of inventory on hand; revenue capped by stock
        maxStock = 5000,
        scaleTiers = {
            { mult = 1.0, cost = 0 },
            { mult = 1.5, cost = math.floor(10000 * 0.75) },
            { mult = 2.5, cost = math.floor(10000 * 1.5) },
        },
        -- ====================================================================
        -- ================== claude_changes_2026-05-25-1330 ==================
        autoReorderEnabled   = false,
        autoReorderThreshold = 0.10,
        autoReorderQuantity  = 0.50,
        requirements = {
            { id='rt_shelves',  type='equipment', key='shelving_unit', minCount=8,  label='Shelving Units',  tier='required'    },
            { id='rt_pos',      type='equipment', key='pos_terminal',  minCount=1,  label='POS Terminal',    tier='required'    },
            { id='rt_cashier',  type='employee',  key='cashier',       minCount=1,  label='Cashier',         tier='required'    },
            { id='rt_stock',    type='stock',     key=nil,             minCount=1,  label='Inventory Stock', tier='required'    },
            { id='rt_cam',      type='equipment', key='security_camera', minCount=4, label='Security Cameras', tier='recommended' },
            { id='rt_cashier2', type='employee',  key='cashier',       minCount=2,  label='Cashiers (2+)',   tier='recommended' },
            { id='rt_floor',    type='employee',  key='floor_staff',   minCount=2,  label='Floor Staff (2+)', tier='recommended' },
            { id='rt_manager',  type='employee',  key='manager',       minCount=1,  label='Manager',         tier='recommended' },
            { id='rt_floor2',   type='employee',  key='floor_staff',   minCount=4,  label='Floor Staff (4+)', tier='bonus'       },
        },
        -- ====================================================================
    },

    -- restaurant is the mid tier high volume option
    -- more revenue per unit than retail but also higher fixed overhead each month
    ['restaurant'] = {
        type = "restaurant",
        displayName = "Restaurant",
        startupCost = 50000,
        basePrice = 20,
        fixedCosts = 5000,
        variableCost = 8,
        capacity = 1500,
        risk = 0.2,
        -- ================== claude_changes_2026-05-25-1228 ==================
        maxEmployees = 14,
        scaleTiers = {
            { mult = 1.0, cost = 0 },
            { mult = 1.5, cost = math.floor(50000 * 0.75) },
            { mult = 2.5, cost = math.floor(50000 * 1.5) },
        },
        -- ====================================================================
        -- ================== claude_changes_2026-05-25-1330 ==================
        stockLevel = 0,             -- food ingredients; revenue gated by stock
        maxStock = 3000,
        unitWholeSaleCost = 5,      -- cost per unit of raw ingredients
        autoReorderEnabled   = false,
        autoReorderThreshold = 0.15,
        autoReorderQuantity  = 0.60,
        requirements = {
            { id='rs_oven',    type='equipment', key='commercial_oven',   minCount=2,  label='Commercial Ovens',   tier='required'    },
            { id='rs_fridge',  type='equipment', key='commercial_fridge', minCount=2,  label='Commercial Fridges', tier='required'    },
            { id='rs_tables',  type='equipment', key='dining_table',      minCount=5,  label='Dining Tables (5+)', tier='required'    },
            { id='rs_chairs',  type='equipment', key='dining_chair',      minCount=20, label='Dining Chairs (20+)', tier='required'   },
            { id='rs_chef',    type='employee',  key='head_chef',         minCount=1,  label='Head Chef',          tier='required'    },
            { id='rs_cook',    type='employee',  key='cook',              minCount=2,  label='Cooks (2+)',         tier='required'    },
            { id='rs_server',  type='employee',  key='server',            minCount=3,  label='Servers (3+)',       tier='required'    },
            { id='rs_ingred',  type='stock',     key=nil,                 minCount=1,  label='Food Ingredients',   tier='required'    },
            { id='rs_bar',     type='equipment', key='bar_setup',         minCount=1,  label='Bar Setup',          tier='recommended' },
            { id='rs_host',    type='employee',  key='host_hostess',      minCount=1,  label='Host/Hostess',       tier='recommended' },
            { id='rs_cook2',   type='employee',  key='cook',              minCount=4,  label='Cooks (4+)',         tier='recommended' },
            { id='rs_server2', type='employee',  key='server',            minCount=5,  label='Servers (5+)',       tier='recommended' },
            { id='rs_bartend', type='employee',  key='bartender',         minCount=1,  label='Bartender',          tier='recommended' },
            { id='rs_mgr',     type='employee',  key='restaurant_manager', minCount=1, label='Manager',            tier='recommended' },
            { id='rs_bartnd2', type='employee',  key='bartender',         minCount=2,  label='Bartenders (2+)',    tier='bonus'       },
            { id='rs_host2',   type='employee',  key='host_hostess',      minCount=2,  label='Hosts (2+)',         tier='bonus'       },
        },
        -- ====================================================================
    },

    -- car dealer is the first big ticket item, high revenue per sale but few units
    -- profit per unit is huge but capacity is tiny so monthly volume is low
    ['car_dealer'] = {
        type = "car_dealer",
        displayName = "Car Dealer",
        startupCost = 100000,
        basePrice = 25000,
        fixedCosts = 20000,
        variableCost = 15000,
        capacity = 10,
        risk = 0.3,
        -- ================== claude_changes_2026-05-25-1228 ==================
        maxEmployees = 12,
        scaleTiers = {
            { mult = 1.0, cost = 0 },
            { mult = 1.5, cost = math.floor(100000 * 0.75) },
            { mult = 2.5, cost = math.floor(100000 * 1.5) },
        },
        -- ====================================================================
        -- ================== claude_changes_2026-05-25-1330 ==================
        requirements = {
            { id='cd_showroom',  type='equipment', key='showroom_display',  minCount=3,  label='Showroom Displays (3+)', tier='required'    },
            { id='cd_sales',     type='employee',  key='salesperson',       minCount=2,  label='Salespeople (2+)',       tier='required'    },
            { id='cd_salesmgr',  type='employee',  key='sales_manager',     minCount=1,  label='Sales Manager',          tier='required'    },
            { id='cd_finmgr',    type='employee',  key='finance_manager',   minCount=1,  label='Finance Manager',        tier='required'    },
            { id='cd_show2',     type='equipment', key='showroom_display',  minCount=6,  label='Showroom Displays (6+)', tier='recommended' },
            { id='cd_lift',      type='equipment', key='vehicle_lift',      minCount=2,  label='Vehicle Lifts',          tier='recommended' },
            { id='cd_detail',    type='equipment', key='detailing_station', minCount=2,  label='Detail Stations',        tier='recommended' },
            { id='cd_sales2',    type='employee',  key='salesperson',       minCount=4,  label='Salespeople (4+)',       tier='recommended' },
            { id='cd_admin',     type='employee',  key='admin_staff',       minCount=1,  label='Admin Staff',            tier='recommended' },
            { id='cd_gm',        type='employee',  key='general_manager',   minCount=1,  label='General Manager',        tier='recommended' },
            { id='cd_sales3',    type='employee',  key='salesperson',       minCount=6,  label='Salespeople (6+)',       tier='bonus'       },
            { id='cd_security',  type='employee',  key='security',          minCount=1,  label='Security',               tier='bonus'       },
        },
        -- ====================================================================
    },

    -- endgame tier, only availible in the endgame biome room
    -- aerospace has huge revenue but also huge risk, can swing wildly
    ['aerospace'] = {
        type = "aerospace",
        displayName = "Aerospace Company",
        startupCost = 10000000,
        basePrice = 1000000,
        fixedCosts = 500000,
        variableCost = 700000,
        capacity = 5,
        risk = 0.8,
        -- ================== claude_changes_2026-05-25-1228 ==================
        maxEmployees = 25,
        scaleTiers = {
            { mult = 1.0, cost = 0 },
            { mult = 1.5, cost = math.floor(10000000 * 0.75) },
            { mult = 2.5, cost = math.floor(10000000 * 1.5) },
        },
        -- ====================================================================
        -- ================== claude_changes_2026-05-25-1330 ==================
        stockLevel = 0,
        maxStock = 20,
        unitWholeSaleCost = 200000,
        autoReorderEnabled   = false,
        autoReorderThreshold = 0.20,
        autoReorderQuantity  = 0.60,
        requirements = {
            { id='ae_mfg',     type='equipment', key='mfg_equipment',      minCount=1,  label='Mfg Equipment',        tier='required'    },
            { id='ae_comp',    type='equipment', key='computer_systems',    minCount=1,  label='Computer Systems',     tier='required'    },
            { id='ae_launch',  type='equipment', key='launch_facility',     minCount=1,  label='Launch Facility',      tier='required'    },
            { id='ae_eng',     type='employee',  key='engineer',            minCount=5,  label='Engineers (5+)',       tier='required'    },
            { id='ae_mfgw',    type='employee',  key='manufacturing_worker', minCount=8, label='Mfg Workers (8+)',    tier='required'    },
            { id='ae_atty',    type='employee',  key='attorney',            minCount=2,  label='Attorneys (2+)',       tier='required'    },
            { id='ae_parts',   type='stock',     key=nil,                   minCount=1,  label='Aerospace Parts',      tier='required'    },
            { id='ae_tunnel',  type='equipment', key='wind_tunnel',         minCount=1,  label='Wind Tunnel',          tier='recommended' },
            { id='ae_eng2',    type='employee',  key='engineer',            minCount=10, label='Engineers (10+)',      tier='recommended' },
            { id='ae_mfgw2',   type='employee',  key='manufacturing_worker', minCount=15, label='Mfg Workers (15+)', tier='recommended' },
            { id='ae_atty2',   type='employee',  key='attorney',            minCount=4,  label='Attorneys (4+)',       tier='recommended' },
            { id='ae_admin',   type='employee',  key='admin_staff',         minCount=3,  label='Admin Staff (3+)',     tier='recommended' },
            { id='ae_exec',    type='employee',  key='executive',           minCount=1,  label='Executive',            tier='recommended' },
            { id='ae_exec2',   type='employee',  key='executive',           minCount=2,  label='Executives (2+)',      tier='bonus'       },
            { id='ae_eng3',    type='employee',  key='engineer',            minCount=15, label='Engineers (15+)',      tier='bonus'       },
        },
        -- ====================================================================
    },

    -- casino is also endgame tier, similar cost to aerospace but different economics
    -- high visitor volume means more consistent income than the low capacity aerospace
    ['casino'] = {
        type = "casino",
        displayName = "Casino",
        startupCost = 9000000,
        basePrice = 100,
        fixedCosts = 500000,
        variableCost = 20,
        capacity = 10000,
        risk = 0.7,
        -- ================== claude_changes_2026-05-25-1228 ==================
        maxEmployees = 25,
        scaleTiers = {
            { mult = 1.0, cost = 0 },
            { mult = 1.5, cost = math.floor(9000000 * 0.75) },
            { mult = 2.5, cost = math.floor(9000000 * 1.5) },
        },
        -- ====================================================================
        -- ================== claude_changes_2026-05-25-1330 ==================
        stockLevel = 0,
        maxStock = 5000,
        unitWholeSaleCost = 30,    -- liquor supply
        autoReorderEnabled   = false,
        autoReorderThreshold = 0.10,
        autoReorderQuantity  = 0.50,
        requirements = {
            { id='ca_surv',    type='equipment', key='surveillance_sys',  minCount=1,  label='Surveillance System',  tier='required'    },
            { id='ca_ctable',  type='equipment', key='card_table',        minCount=4,  label='Card Tables (4+)',     tier='required'    },
            { id='ca_slots',   type='equipment', key='slot_machine',      minCount=10, label='Slot Machines (10+)',  tier='required'    },
            { id='ca_dealer',  type='employee',  key='card_dealer',       minCount=5,  label='Card Dealers (5+)',    tier='required'    },
            { id='ca_pit',     type='employee',  key='pit_boss',          minCount=1,  label='Pit Boss',             tier='required'    },
            { id='ca_sec',     type='employee',  key='security',          minCount=3,  label='Security (3+)',        tier='required'    },
            { id='ca_bar',     type='equipment', key='casino_bar',        minCount=1,  label='Casino Bar',           tier='recommended' },
            { id='ca_slots2',  type='equipment', key='slot_machine',      minCount=20, label='Slot Machines (20+)',  tier='recommended' },
            { id='ca_ctable2', type='equipment', key='card_table',        minCount=8,  label='Card Tables (8+)',     tier='recommended' },
            { id='ca_dealer2', type='employee',  key='card_dealer',       minCount=10, label='Card Dealers (10+)',   tier='recommended' },
            { id='ca_bartend', type='employee',  key='bartender',         minCount=2,  label='Bartenders (2+)',      tier='recommended' },
            { id='ca_wait',    type='employee',  key='cocktail_waitress', minCount=4,  label='Cocktail Waitresses',  tier='recommended' },
            { id='ca_gm',      type='employee',  key='general_manager',   minCount=1,  label='General Manager',      tier='recommended' },
            { id='ca_liquor',  type='stock',     key=nil,                 minCount=1,  label='Liquor Supply',        tier='recommended' },
            { id='ca_vip',     type='equipment', key='vip_room',          minCount=1,  label='VIP Room',             tier='bonus'       },
            { id='ca_wait2',   type='employee',  key='cocktail_waitress', minCount=8,  label='Cocktail Waitresses (8+)', tier='bonus'   },
        },
        -- ====================================================================
    }
}

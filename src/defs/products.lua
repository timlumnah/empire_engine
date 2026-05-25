--[[
   Empire Engine
   Based on CS50 2D Coursework

   -- Products that the player can buy/consume --

   Author: Tim Lumnah
   github.com/timlumnah/empire_engine

   bevarage = +1 thirst
   food = +1 hunger
   healthScore = + (item.healthScore / 2) 
    vendor defs are in vendors.lua
    Not every item has every category
]]

-- all buyable products, keyed by product string id
-- each entry is used by MarketplaceMenu to build the store listing
-- "vendors" list tells the store which vendors sell this item
-- healthScore is divided by 2 when the player consumes, see InventoryMenu:consume
-- ================== claude_changes_2026-05-25-1228 ==================
-- playerBuyable = true  : appears in the C-menu STORE for the player to purchase
-- wholesaleSellable = true : can be stocked in a retail business via WHOLESALE tab
-- (wholesale tab for now uses abstract units; these flags reserve intent for future)
-- ====================================================================
PRODUCTS = {

    -- computer type, gives player access to the marketplace when owned
    -- ybooklet is the new version, used ybooklet is cheaper but from a secondhand vendor
    ['ybooklet'] = {
        type = "computer",          -- computer type unlocks the C key marketplace
        displayName = "yBooklet",
        price = 1125,               -- base price before vendor surcharge
        vendors = {"zamabon"},      -- only sold through zamabon
        heat = 0,                   -- heat field, not currently used in gameplay
        playerBuyable = true,
    },
    ['used_ybooklet'] = {
        type = "computer",
        displayName = "Used yBooklet",
        price = 500,                -- cheaper used option from slaptick
        vendors = {"slaptick"},
        heat = 1,                   -- nonzero heat marks it as secondhand
        playerBuyable = true,
    },

    -- phone type, also unlocks the marketplace like a computer does
    ['yphone'] = {
        type = "phone",             -- phone type also unlocks the C key marketplace
        displayName = "yPhone",
        price = 995,
        vendors = {"zamabon"},
        heat = 0,
        playerBuyable = true,
    },
    ['used_yphone'] = {
        type = "phone",
        displayName = "Used yPhone",
        price = 335,
        vendors = {"slaptick"},
        heat = 1,
        playerBuyable = true,
    },

    -- car type, shows as owned equipment in inventory, no consume effect
    ['monzda'] = {
        type = "car",               -- car type, no gameplay mechanic attatched yet
        displayName = "monzda",
        price = 8125,
        vendors = {"slaptick"},     -- only availble through the secondhand vendor
        playerBuyable = true,
    },

    -- food items, consuming restores 33 percent of max hunger
    -- negative healthScore means eating it actualy hurts you a tiny bit
    ['pizza'] = {
        type = "food",
        displayName = "Pizza",
        price = 18,
        healthScore = -5,           -- junk food, consuming costs 2.5 HP
        vendors = {"grabgrub"},     -- only from the delivery vendor
        playerBuyable = true,
    },
    ['burger_fries'] = {
        type = "food",
        displayName = "Burger & Fries",
        price = 17,
        healthScore = -6,           -- slightly worse for you than pizza
        vendors = {"grabgrub"},
        playerBuyable = true,
    },

    -- healthier food options from the grocery vendor
    ['apple'] = {
        type = "food",
        displayName = "Apple",
        price = 1,                  -- cheapest food item
        healthScore = 10,           -- best health return of any food, gives 5 HP back
        vendors = {"foodcircle"},
        playerBuyable = true,
    },
    ['lettuce'] = {
        type = "food",
        displayName = "Lettuce",
        price = 1,
        healthScore = 3,            -- modest health boost, cheaper than an apple
        vendors = {"foodcircle"},
        playerBuyable = true,
    },
    ['chips'] = {
        type = "food",
        displayName = "Cordito Chips",
        price = 1,
        healthScore = -4,           -- tastes good but hurts health slightly
        vendors = {"foodcircle"},
        playerBuyable = true,
    },

    -- beverage items, consuming restores 33 percent of max thirst
    -- soda available from two vendors so player has more buying options
    ['soda'] = {
        type = "beverage",
        displayName = "PopTooth Soda",
        price = 2,
        healthScore = -8,           -- bad for health, costs 4 HP when consumed
        vendors = {"foodcircle", "grabgrub"}, -- availible from grocery or delivery
        bulk_enabled = true,        -- can be ordered in bulk from supported vendors
        playerBuyable = true,
    },
    ['bottled_water'] = {
        type = "beverage",
        displayName = "Bottle of Water",
        price = 2,
        healthScore = 8,            -- best health return of any beverage, gives 4 HP
        vendors = {"foodcircle", "grabgrub"},
        bulk_enabled = true,
        playerBuyable = true,
    },

    -- bandage is typed as food so InventoryMenu lets the player consume it
    -- this is a workaround since consume only works on food and beverage types
    ['bandage'] = {
        type = "food",              -- its not food but this lets the player consume it
        displayName = "Bandage",
        price = 5,
        healthScore = 12,           -- best health item in the game, heals 6 HP
        vendors = {"zamabon", "foodcircle", "grabgrub"}, -- sold by three vendors
        bulk_enabled = true,
        playerBuyable = true,
    },

    -- ================== claude_changes_2026-05-25-1228 ==================
    -- wholesale-only items: not sold in the C-menu store; stocked by retail businesses
    -- playerBuyable = false keeps them out of build_product_list()
    ['retail_merchandise'] = {
        type = "merchandise",
        displayName = "Retail Merchandise",
        price = 4,                  -- wholesale unit cost; matches retail unitWholeSaleCost
        vendors = {"zamabon"},
        playerBuyable = false,
        wholesaleSellable = true,
        bulk_enabled = true,
    },
    -- ====================================================================
}

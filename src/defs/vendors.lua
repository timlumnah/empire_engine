--[[
   Empire Engine
   Based on CS50 2D Coursework

   -- Vendors that the player can purchase in-game items from --

   Author: Tim Lumnah
   github.com/timlumnah/empire_engine

    Zamabon = Amazon analgue
    SlapTick = Facebook marketplace analogue
    FoodCircle = Wholefoods analogue
    GrabGrub = Doordash / grubhub analogue

    price_surcharge = the upcharge that the vendor applies to product price from PRODUCTS defs
    bulk_qty_opts = the vendor sells items in these qtys.  Item MUST have bulk_enabled = true in PRODUCTS defs.
    max_bulk_discount = that maximum discount, expressed as decimal, and applied linearly to bulk_qty_opts
]]

-- each vendor has different delivery speeds and price markups
-- surcharge is applied on top of the base price defined in PRODUCTS
-- vendor keys must match the "vendors" lists in each product def
-- VENDOR_DELIVERY_SPEED constant from constants.lua is the base delivery time in seconds
VENDORS = {

    -- amazon analogue, reliable with bulk discounts, slightly slow delivery
    ['zamabon'] = {
        displayName = "Zamabon",
        priceSurcharge = 0.05,      -- adds 5 percent on top of the product base price
        bulk_qty_opts = {5, 10, 20, 30, 50, 100}, -- bulk order sizes availible for eligible products
        max_bulk_discount = 0.15,   -- up to 15 percent off for largest bulk orders
        delivery_speed_multiplier = 1.2     -- multiplied against VENDOR_DELIVERY_SPEED, higher is slower
    },

    -- facebook marketplace analogue, cheapest prices but no bulk and peer to peer only
    ['slaptick'] = {
        displayName = "SlapTick",
        priceSurcharge = -0.05,     -- negative surcharge means its actualy cheaper than base
        bulk_qty_opts = { },        -- no bulk orders, its a person to person sale
        delivery_speed_multiplier = 0.8     -- fastest delivery since its local pickup style
    },

    -- whole foods analogue, premium grocery store, bulk available but expensive
    ['foodcircle'] = {
        displayName = "FoodCircle",
        priceSurcharge = 0.1,       -- 10 percent premium, organic and fancy
        bulk_qty_opts = {3, 5, 10}, -- smaller bulk tiers than zamabon
        max_bulk_discount = 0.10,   -- modest 10 percent max bulk discount
        delivery_speed_multiplier = 1.2 -- same slow delivery as zamabon
    },

    -- doordash analogue, most expensive because of the delivery surcharge
    -- convenient but you pay for it, no bulk since its restaurant delivery
    ['grabgrub'] = {
        displayName = "GrabGrub",
        priceSurcharge = 0.2,       -- 20 percent surcharge, the most expesive vendor
        bulk_qty_opts = { },        -- cant order bulk from a food delivery app
        delivery_speed_multiplier = 1.1 -- slightly slower than slaptick but faster than grocery
    },
}

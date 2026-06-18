local MOD_NAME = "Fast Start Kit"

local function item_exists(name)
  if not name then return false end
  if prototypes and prototypes.item and prototypes.item[name] then
    return true
  end
  if game and game.item_prototypes and game.item_prototypes[name] then
    return true
  end
  return false
end

local function first_existing(names)
  for _, name in pairs(names) do
    if item_exists(name) then
      return name
    end
  end
  return nil
end

local function ensure_storage()
  storage.fast_start_kit = storage.fast_start_kit or {}
  storage.fast_start_kit.given = storage.fast_start_kit.given or {}
end

local function safe_insert(inv, stack)
  if inv and inv.valid and stack and item_exists(stack.name) then
    inv.insert(stack)
  end
end

local function put_equipment(grid, name, count)
  if not grid or not grid.valid or not item_exists(name) then return 0 end

  local placed = 0
  for _ = 1, count do
    local ok, equipment = pcall(function()
      return grid.put({ name = name })
    end)

    if ok and equipment then
      placed = placed + 1
    else
      break
    end
  end

  return placed
end

local function find_power_armor_stack(player, main_inv)
  local armor_inv = player.get_inventory(defines.inventory.character_armor)
  if armor_inv and armor_inv.valid and armor_inv[1] and armor_inv[1].valid_for_read and armor_inv[1].grid then
    return armor_inv[1]
  end

  if main_inv and main_inv.valid then
    for i = 1, #main_inv do
      local stack = main_inv[i]
      if stack and stack.valid_for_read and stack.name == "power-armor-mk2" and stack.grid then
        return stack
      end
    end
  end

  return nil
end

local function give_armor(player, main_inv)
  local armor_name = "power-armor-mk2"
  if not item_exists(armor_name) then return nil end

  local armor_inv = player.get_inventory(defines.inventory.character_armor)
  if armor_inv and armor_inv.valid and armor_inv[1] and not armor_inv[1].valid_for_read then
    armor_inv[1].set_stack({ name = armor_name, count = 1 })
    return armor_inv[1]
  end

  if main_inv and main_inv.valid then
    safe_insert(main_inv, { name = armor_name, count = 1 })
    return find_power_armor_stack(player, main_inv)
  end

  return nil
end

local function fill_armor_grid(armor_stack)
  if not armor_stack or not armor_stack.valid_for_read or not armor_stack.grid then return end

  local grid = armor_stack.grid
  grid.clear()

  local reactor = first_existing({
    "fission-reactor-equipment",
    "fusion-reactor-equipment"
  })

  local battery = first_existing({
    "battery-mk3-equipment",
    "battery-mk2-equipment",
    "battery-equipment"
  })

  local roboport = first_existing({
    "personal-roboport-mk2-equipment",
    "personal-roboport-equipment"
  })

  local shield = first_existing({
    "energy-shield-mk2-equipment",
    "energy-shield-equipment"
  })

  -- Full 10x10 Power Armor MK2 builder loadout:
  -- 2 reactors, 4 exoskeletons, 4 personal roboports, 6 batteries, 2 shields.
  -- This exactly fills the vanilla 100-tile MK2 grid when MK2 equipment is available.
  if reactor then put_equipment(grid, reactor, 2) end
  put_equipment(grid, "exoskeleton-equipment", 4)
  if roboport then put_equipment(grid, roboport, 4) end
  if battery then put_equipment(grid, battery, 6) end
  if shield then put_equipment(grid, shield, 2) end
end

local function grant_fast_start(player, force)
  if not player or not player.valid or not player.character then return end
  ensure_storage()

  if not force and storage.fast_start_kit.given[player.index] then
    return
  end

  local main_inv = player.get_main_inventory()
  if not main_inv or not main_inv.valid then return end

  local armor_stack = give_armor(player, main_inv)
  fill_armor_grid(armor_stack)

  safe_insert(main_inv, { name = "fast-start-construction-robot", count = 50 })
  safe_insert(main_inv, { name = "repair-pack", count = 100 })

  storage.fast_start_kit.given[player.index] = true
  player.print({ "", "[", MOD_NAME, "] Builder kit granted: full Power Armor MK2 grid, 50 Fast Start construction bots, and 100 repair packs." })
end

script.on_init(function()
  ensure_storage()
  for _, player in pairs(game.players) do
    grant_fast_start(player, false)
  end
end)

script.on_configuration_changed(function()
  ensure_storage()
end)

script.on_event(defines.events.on_player_created, function(event)
  local player = game.get_player(event.player_index)
  grant_fast_start(player, false)
end)

script.on_event(defines.events.on_player_respawned, function(event)
  local player = game.get_player(event.player_index)
  grant_fast_start(player, false)
end)

commands.add_command("fast-start-kit", "Gives the Fast Start Kit again. Admins can use: /fast-start-kit <player>", function(command)
  local caller = command.player_index and game.get_player(command.player_index) or nil
  local target = caller

  if command.parameter and command.parameter ~= "" then
    if caller and not caller.admin then
      caller.print("Only admins can give the kit to another player.")
      return
    end

    target = game.get_player(command.parameter)
    if not target then
      if caller then caller.print("Player not found: " .. command.parameter) end
      return
    end
  end

  if target then
    grant_fast_start(target, true)
    if caller and caller ~= target then
      caller.print("Fast Start Kit granted to " .. target.name .. ".")
    end
  end
end)

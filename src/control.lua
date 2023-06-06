global.personalSpidertrons = {}
global.cutsceneCompleted = false

script.on_event(defines.events.on_cutscene_cancelled, function(event)
    global.cutsceneCompleted = true
end)

script.on_event(defines.events.on_player_created, function(event)
    script.on_nth_tick(1, function()
        if not global.cutsceneCompleted then
            return
        end

        createSpidertron(event.player_index)
        game.get_player(event.player_index).print("You have received a Personal Spidertron!")

        script.on_nth_tick(1, nil)
    end)
end)

script.on_event(defines.events.on_player_removed, function(event)
    deleteSpidertron(event.player_index)
end)

script.on_event(defines.events.on_player_kicked, function(event)
    hideSpidertron(event.player_index)
end)

script.on_event(defines.events.on_player_banned, function(event)
    hideSpidertron(event.player_index)
end)

script.on_event(defines.events.on_player_left_game, function(event)
    hideSpidertron(event.player_index)
end)

script.on_event(defines.events.on_player_joined_game, function(event)
    showSpidertron(event.player_index)
end)

script.on_event(defines.events.on_entity_died, function(event)
    local owner_index = getSpidertronOwnerIndex(event.entity.unit_number)

    if not owner_index then
        return
    end

    global.personalSpidertrons[owner_index] = nil
    createSpidertron(owner_index, game.surfaces["nauvis"].find_non_colliding_position("spidertron", { x = 0, y = 0 }, 0, 1))
    player.print("Your Personal Spidertron died, not to worry there's a new one waiting at the spawn!")
end)

script.on_event(defines.events.on_player_driving_changed_state, function(event)
    local player = game.get_player(event.player_index)
    local isOwner = playerOwnsSpidertron(event.player_index, event.entity)

    if not player.driving then
        return
    end

    if isOwner then
        event.entity.color = player.color
    elseif isOwner == false then
        player.driving = false
        player.print("You cannot drive " .. event.entity.entity_label)
    end
end)

script.on_event(defines.events.on_gui_opened, function(event)
    if playerOwnsSpidertron(event.player_index, event.entity) ~= false then
        return
    end

    local player = game.get_player(event.player_index)
    player.opened = nil
    player.print("You cannot access " .. event.entity.entity_label)
end)

script.on_event(defines.events.on_player_configured_spider_remote, function(event)
    local player = game.get_player(event.player_index)

    if not player.cursor_stack or not player.cursor_stack.valid_for_read or player.cursor_stack.name ~= "spidertron-remote" then
        return
    end

    if playerOwnsSpidertron(event.player_index, player.cursor_stack.connected_entity) ~= false then
        return
    end

    player.cursor_stack.connected_entity = nil
    player.print("You cannot connect to " .. player.cursor_stack.connected_entity.entity_label)
end)

script.on_event(defines.events.on_player_removed_equipment, function(event)
    if not getSpidertronGridOwnerIndex(event.grid.unique_id) then
        return
    end

    local player = game.get_player(event.player_index)

    if player.cursor_stack and player.cursor_stack.valid_for_read then
        local item_stack = { name = player.cursor_stack.name, count = player.cursor_stack.count }
        player.cursor_stack.clear()
        player.insert(item_stack)
    end

    player.remove_item({name = event.equipment, count = event.count})

    for _ = 1, event.count do
        event.grid.put({ name = event.equipment })
    end

    player.print("You cannot remove equipment from your personal Spidertron")
end)

function createSpidertron(player_index, position)
    if global.personalSpidertrons[player_index] then
        return
    end

    local player = game.get_player(player_index)

    if not position then
        position = player.position
    end

    local spidertron = player.surface.create_entity { name = "spidertron", position = position, force = player.force }
    spidertron.entity_label = player.name .. "'s Spidertron"
    spidertron.minable = false
    spidertron.operable = true
    spidertron.color = player.color

    for _ = 1, 3 do
        spidertron.grid.put({ name = "exoskeleton-equipment" })
    end
    for _ = 1, 2 do
        spidertron.grid.put({ name = "personal-laser-defense-equipment" })
    end
    for _ = 1, 2 do
        spidertron.grid.put({ name = "energy-shield-equipment" })
    end
    for _ = 1, 2 do
        spidertron.grid.put({ name = "battery-equipment" })
    end
    for _ = 1, 16 do
        spidertron.grid.put({ name = "solar-panel-equipment" })
    end

    player.insert { name = "spidertron-remote", count = 1 }
    player.get_main_inventory().find_item_stack("spidertron-remote").connected_entity = spidertron

    global.personalSpidertrons[player.index] = spidertron
end

function hideSpidertron(player_index)
    local spidertron = global.personalSpidertrons[player_index]
    if not spidertron or not spidertron.valid then
        return
    end

    spidertron.active = false
    spidertron.destructible = false

    local surface = "offline_personal_spidertrons"
    if not game.surfaces[surface] then
        game.create_surface(surface, { width = 100, height = 100})
    end

    spidertron.teleport({x = 0, y = 0}, game.surfaces[surface])
end

function deleteSpidertron(player_index)
    local spidertron = global.personalSpidertrons[player_index]
    if not spidertron or not spidertron.valid then
        return
    end

    spidertron.active = false
    spidertron.destructible = true
    spidertron.destroy()
    global.personalSpidertrons[player_index] = nil
end

function showSpidertron(player_index)
    local spidertron = global.personalSpidertrons[player_index]
    if not spidertron or not spidertron.valid then
        return
    end

    spidertron.active = true
    spidertron.destructible = true
    spidertron.teleport(game.get_player(player_index).position, game.surfaces["nauvis"])
end

function getSpidertronOwnerIndex(unit_number)
    for player_index, spidertron in pairs(global.personalSpidertrons) do
        if spidertron and spidertron.valid and spidertron.unit_number == unit_number then
            return player_index
        end
    end

    return
end

function playerOwnsSpidertron(player_index, spidertron)
    if not spidertron or not spidertron.valid or spidertron.type ~= "spider-vehicle" then
        return
    end

    local owner_index = getSpidertronOwnerIndex(spidertron.unit_number)

    if not owner_index then
        return
    end

    return player_index == owner_index
end

function getSpidertronGridOwnerIndex(unique_id)
    for player_index, spidertron in pairs(global.personalSpidertrons) do
        if spidertron and spidertron.valid and spidertron.grid.unique_id == unique_id then
            return player_index
        end
    end
    return nil
end
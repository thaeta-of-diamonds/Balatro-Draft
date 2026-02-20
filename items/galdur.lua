-- GALDUR (1.1.4+) COMPATIBILITY
local min_galdur_version = '1.1.4'
local quick_start_draft_node = nil

local hovered_draft_mode = nil

local function populate_info_queue(set, key)
    -- direct copy from galdur, but I need it outside of galdur
    local info_queue = {}
    local loc_target = G.localization.descriptions[set][key]
    for _, lines in ipairs(loc_target.text_parsed) do
        for _, part in ipairs(lines) do
            if part.control.T then info_queue[#info_queue + 1] = G.P_CENTERS[part.control.T] or G.P_TAGS[part.control.T] end
        end
    end
    return info_queue
end

local function create_fake_draft_mode(draft_mode)
    -- shallow copy of given draft_mode object
    -- this is so hacky I hate it
    local fake_draft_mode = {}
    fake_draft_mode.fake_draft_mode = true
    for k, v in pairs(draft_mode) do
        if k == "config" and type(v) == "table" then
            fake_draft_mode[k] = {}
            for k2, v2 in pairs(v) do
                -- deep-ish copy of config table in case other modders do weird stuff with the config table
                fake_draft_mode[k][k2] = v2
            end
        else
            fake_draft_mode[k] = v
        end
    end
    setmetatable(fake_draft_mode, getmetatable(draft_mode))
    return fake_draft_mode
end

local function create_draft_mode_unlock_message(draft_mode)
    return {}
end

local card_stop_hover = Card.stop_hover
function Card:stop_hover()
    if self.params.stake_draft_mode_selectorchip then
        Galdur.hover_index = 0
    end
    card_stop_hover(self)
end

local card_hover_ref = Card.hover
function Card:hover()
    if self.params.draft_mode_selector and (not self.states.drag.is or G.CONTROLLER.HID.touch) and not self.no_ui and not G.debug_tooltip_toggle then
        Galdur.hover_index = self.params.hover or 0
        self:juice_up(0.05, 0.03)
        play_sound('paper1', math.random() * 0.2 + 0.9, 0.35)

        local info_queue = populate_info_queue('Draft_Mode', G.P_CENTER_POOLS.Draft_Mode[self.params.draft_mode].key)
        local tooltips = {}
        for _, center in pairs(info_queue) do
            local desc = generate_card_ui(center, { main = {}, info = {}, type = {}, name = 'done' }, nil, center.set,
                nil)
            tooltips[#tooltips + 1] =
            {
                n = G.UIT.C,
                config = { align = "bm" },
                nodes = {
                    {
                        n = G.UIT.R,
                        config = { align = "cm", colour = lighten(G.C.JOKER_GREY, 0.5), r = 0.1, padding = 0.05, emboss = 0.05 },
                        nodes = {
                            info_tip_from_rows(desc.info[1], desc.info[1].name),
                        }
                    }
                }
            }
        end

        local badges = { n = G.UIT.ROOT, config = { colour = G.C.CLEAR, align = 'cm' }, nodes = {} }
        SMODS.create_mod_badges(G.P_CENTER_POOLS.Draft_Mode[self.params.draft_mode], badges.nodes)
        if badges.nodes.mod_set then badges.nodes.mod_set = nil end


        self.config.h_popup = self.params.draft_mode_locked and
        {
            n = G.UIT.ROOT,
            config = { align = "cm", colour = G.C.BLACK, r = 0.1, padding = 0.1, outline = 1 },
            nodes = {
                {
                    n = G.UIT.C,
                    config = { align = "cm", padding = 0.05, r = 0.1, colour = G.C.L_BLACK },
                    nodes = {
                        {
                            n = G.UIT.R,
                            config = { align = "cm", padding = 0 },
                            nodes = {
                                { n = G.UIT.T, config = { text = localize('gald_locked'), scale = 0.4, colour = G.C.WHITE } }
                            }
                        },
                        {
                            n = G.UIT.R,
                            config = { align = "cm", padding = 0.03, colour = G.C.WHITE, r = 0.1, minh = 1, minw = 3.5 },
                            nodes =
                                create_draft_mode_unlock_message(G.P_CENTER_POOLS.Draft_Mode[self.params.draft_mode])
                        }
                    }
                }
            }
        } or {
            n = G.UIT.ROOT,
            config = { align = 'cm', colour = G.C.CLEAR },
            nodes = {
                { n = G.UIT.R, config = { align = 'cm', padding = 0.1 }, nodes = tooltips },
                {
                    n = G.UIT.C,
                    config = { align = "cm", padding = 0.1, colour = G.C.BLACK, r = 0.1, outline = 1 },
                    nodes = {
                        {
                            n = G.UIT.R,
                            nodes = {
                                {
                                    n = G.UIT.C,
                                    config = { align = "cm", padding = 0 },
                                    nodes = {
                                        { n = G.UIT.T, config = { text = localize('k_draft_draft_mode'), scale = 0.4, colour = G.C.L_BLACK, vert = true } }
                                    }
                                },
                                {
                                    n = G.UIT.C,
                                    config = { align = "cm", padding = 0 },
                                    nodes = {
                                        { n = G.UIT.O, config = { colour = G.C.BLUE, object = get_draft_mode_sprite(G.P_CENTER_POOLS.Draft_Mode[self.params.draft_mode].key), hover = true, can_collide = false } },
                                    }
                                },
                                {
                                    n = G.UIT.C,
                                    config = { align = "cm", padding = 0 },
                                    nodes = {
                                        G.UIDEF.draft_mode_description(G.P_CENTER_POOLS.Draft_Mode
                                        [self.params.draft_mode].key)
                                    }
                                }
                            }
                        },
                        badges.nodes[1] and {
                            n = G.UIT.R,
                            config = { align = "cm" },
                            nodes = {
                                { n = G.UIT.O, config = { object = UIBox { definition = badges, config = { offset = { x = 0, y = 0 } } } } }
                            }
                        },
                    }
                }
            }
        }

        self.config.h_popup_config = self:align_h_popup()
        Node.hover(self)
    else
        card_hover_ref(self)
    end
end

G.FUNCS.random_draft_mode = function()
    local random
    local random_draft_opts = {}
    for i = 1, #G.P_CENTER_POOLS.Draft_Mode do
        if G.P_CENTER_POOLS.Draft_Mode[i]:is_unlocked() then
            random_draft_opts[#random_draft_opts + 1] = i
        end
    end
    while not random do
        random = pseudorandom_element(random_draft_opts, pseudoseed(os.time()))
        if G.P_CENTER_POOLS.Draft_Mode[random].key == G.viewed_draft_mode and #random_draft_opts > 1 then
            random = false
        end
    end
    play_sound('whoosh1', math.random() * 0.2 + 0.9, 0.35)
    G.FUNCS.change_draft_mode { to_key = random }
    Galdur.populate_draft_mode_card_areas {}
end

local draft_mode_areas = {}

-- Draft Mode Selection Functions
local function generate_draft_mode_card_areas()
    if draft_mode_areas then
        for i = 1, #draft_mode_areas do
            for j = 1, #G.I.CARDAREA do
                if draft_mode_areas[i] == G.I.CARDAREA[j] then
                    table.remove(G.I.CARDAREA, j)
                    draft_mode_areas[i] = nil
                end
            end
        end
    end
    draft_mode_areas = {}
    for i = 1, 24 do
        draft_mode_areas[i] = CardArea(G.ROOM.T.w * 0.116, G.ROOM.T.h * 0.209, 3.4 * 14 / 41, 3.4 * 14 / 41,
            { card_limit = 1, type = 'deck', highlight_limit = 0, draft_mode_select = true })
    end
end

local function get_draft_mode_sprite_in_area(_draft_mode, _scale, _area)
    _draft_mode = _draft_mode or 1
    local draft_mode = G.P_CENTER_POOLS.Draft_Mode[_draft_mode]
    _scale = _scale or 1
    _area = _area.T or { x = 0, y = 0 }
    local draft_mode_sprite = Sprite(_area.x, _area.y, _scale * 1, _scale * 1, G.ASSET_ATLAS[draft_mode.atlas],
        draft_mode.pos)
    draft_mode_sprite.states.drag.can = false
    if draft_mode.key == G.viewed_draft_mode then
        draft_mode_sprite.draw = function(_sprite)
            _sprite.ARGS.send_to_shader = _sprite.ARGS.send_to_shader or {}
            _sprite.ARGS.send_to_shader[1] = math.min(_sprite.VT.r * 3, 1) + G.TIMERS.REAL / (18) +
            (_sprite.juice and _sprite.juice.r * 20 or 0) + 1
            _sprite.ARGS.send_to_shader[2] = G.TIMERS.REAL

            Sprite.draw_shader(_sprite, 'dissolve')
            Sprite.draw_shader(_sprite, 'voucher', nil, _sprite.ARGS.send_to_shader)
        end
    else
        draft_mode_sprite.draw = function(_sprite)
            _sprite.ARGS.send_to_shader = _sprite.ARGS.send_to_shader or {}
            _sprite.ARGS.send_to_shader[1] = math.min(_sprite.VT.r * 3, 1) + G.TIMERS.REAL / (18) +
            (_sprite.juice and _sprite.juice.r * 20 or 0) + 1
            _sprite.ARGS.send_to_shader[2] = G.TIMERS.REAL

            Sprite.draw_self(_sprite, G.C.L_BLACK)
            Sprite.draw_shader(_sprite, 'negative_shine', nil, _sprite.ARGS.send_to_shader)
        end
    end
    return draft_mode_sprite
end

local function populate_draft_mode_card_areas(page)
    Draft.draft_mode_page = page
    local count = 1 + (page - 1) * 24
    for i = 1, 24 do
        if count > #G.P_CENTER_POOLS.Draft_Mode then return end
        local card = Card(draft_mode_areas[i].T.x, draft_mode_areas[i].T.y, 3.4 * 14 / 41, 3.4 * 14 / 41,
            G.P_CENTER_POOLS.Draft_Mode[count], G.P_CENTER_POOLS.Draft_Mode[count],
            { draft_mode_selector = true, draft_mode = count, galdur_selector = true })
        card.facing = 'back'
        card.sprite_facing = 'back'
        card.children.back = get_draft_mode_sprite_in_area(count, 3.4 * 14 / 41, card)

        local unlocked = G.P_CENTER_POOLS.Draft_Mode[count].unlocked
        if not unlocked then
            card.params.draft_mode_locked = true
            card.children.back:remove()
            card.children.back = Sprite(card.T.x, card.T.y, 3.4 * 14 / 41, 3.4 * 14 / 41,
                G.ASSET_ATLAS['galdur_tag_atlas'], { x = 6, y = 0 })
        end
        card.children.back.states.hover = card.states.hover
        card.children.back.states.click = card.states.click
        card.children.back.states.drag = card.states.drag
        card.states.collide.can = false
        card.children.back:set_role({ major = card, role_type = 'Glued', draw_major = card })
        card.params["draft_mode_select"] = i
        draft_mode_areas[i]:emplace(card)
        count = count + 1
    end
end

function Galdur.clean_up_functions.clean_draft_mode_areas()
    if not draft_mode_areas then return end
    for j = 1, #draft_mode_areas do
        if draft_mode_areas[j].cards then
            remove_all(draft_mode_areas[j].cards)
            draft_mode_areas[j].cards = {}
        end
    end
end

local function generate_draft_mode_card_areas_ui()
    local draft_mode_ui_element = {}
    local count = 1
    local min_rows = math.ceil(#G.P_CENTER_POOLS.Draft_Mode / 8)
    for i = 1, math.min(3, min_rows) do
        local row = { n = G.UIT.R, config = { colour = G.C.LIGHT, padding = 0.1 }, nodes = {} }
        for j = 1, 8 do
            table.insert(row.nodes,
                { n = G.UIT.O, config = { object = draft_mode_areas[count], r = 0.1, id = "draft_mode_select_" .. count, count = 1, outline_colour = G.C.YELLOW, focus_args = { snap_to = true } } })
            count = count + 1
        end
        table.insert(draft_mode_ui_element, row)
    end

    populate_draft_mode_card_areas(1)

    return { n = G.UIT.R, config = { align = "cm", minh = 0.45 + G.CARD_H + G.CARD_H, minw = 10.7, colour = G.C.BLACK, padding = 0.15, r = 0.1, emboss = 0.05 }, nodes =
    draft_mode_ui_element }
end

G.FUNCS.change_draft_mode_page = function(args)
    Galdur.clean_up_functions.clean_draft_mode_areas()
    populate_draft_mode_card_areas(args.to)
end

local card_click_ref = Card.click
function Card:click()
    if self.params.draft_mode_selector and not self.params.draft_mode_locked then
        Galdur.run_setup.choices.draft_mode = G.P_CENTER_POOLS.Draft_Mode[self.params.draft_mode].key
        G.E_MANAGER:clear_queue('galdur')
        G.FUNCS.change_draft_mode { to_key = self.params.draft_mode }
        G.FUNCS.change_draft_mode_page {to = Draft.draft_mode_page}
    else
        card_click_ref(self)
    end
end

local function create_draft_mode_page_cycle()
    local options = {}
    local total_pages = math.ceil(#G.P_CENTER_POOLS.Draft_Mode / 24)
    for i = 1, total_pages do
        table.insert(options, localize('k_page') .. ' ' .. i .. ' / ' .. total_pages)
    end
    local cycle = EremelUtility.page_cycler({
        object_table = G.P_CENTER_POOLS.Draft_Mode,
        page_size = 24,
        key = 'draft_mode_cycler',
        switch_func = G.FUNCS.change_draft_mode_page,
        h = 1
    })

    return { n = G.UIT.R, config = { align = "cm" }, nodes = { cycle } }
end


local function deck_select_page_draft_mode()
    G.FUNCS.change_draft_mode { key = G.viewed_draft_mode or G.PROFILES[G.SETTINGS.profile].MEMORY.draft_mode or "mode_draft_casl_none" }
    Galdur.include_deck_preview()
    Galdur.include_chip_tower()
    generate_draft_mode_card_areas()

    local deck_preview = Galdur.display_deck_preview()
    deck_preview.nodes[#deck_preview.nodes + 1] = {
        n = G.UIT.R,
        config = { align = 'cm', padding = 0.15 },
        nodes = {
            {
                n = G.UIT.C,
                config = { maxw = 2.5, minw = 2.5, minh = 0.8, r = 0.1, hover = true, ref_value = 1, button = 'random_draft_mode', colour = Galdur.badge_colour, align = "cm", emboss = 0.1 },
                nodes = {
                    { n = G.UIT.R, config = { align = 'cm' }, nodes = { { n = G.UIT.T, config = { text = localize('gald_random_draft_mode'), scale = 0.4, colour = G.C.WHITE } } } },
                    { n = G.UIT.R, config = { align = 'cm' }, nodes = { { n = G.UIT.C, config = { func = 'set_button_pip', focus_args = { button = 'triggerright', set_button_pip = true, offset = { x = -0.2, y = 0.3 } } } } } }
                }
            }
        }
    }

    return
    {
        n = G.UIT.ROOT,
        config = { align = "tm", minh = 3.8, colour = G.C.CLEAR, padding = 0.1 },
        nodes = {
            {
                n = G.UIT.C,
                config = { padding = 0.15 },
                nodes = {
                    generate_draft_mode_card_areas_ui(),
                    create_draft_mode_page_cycle(),
                }
            },
            Galdur.display_chip_tower(),
            deck_preview
        }
    }
end


local function quick_start_text()
    if not quick_start_draft_node then
        quick_start_draft_node = G.viewed_draft_mode or G.PROFILES[G.SETTINGS.profile].MEMORY.draft_mode or "casl_none"
    end
    local draft_mode_center = Draft.Draft_Mode:get_obj(quick_start_draft_node)
    if draft_mode_center then
        local ret_nodes, full_UI_table = {}, {}
        draft_mode_center.generate_ui(create_fake_draft_mode(draft_mode_center), {}, nil, ret_nodes, nil, full_UI_table)
        local draft_mode_name = full_UI_table.name or ret_nodes.name
        return draft_mode_name
    else
        return "ERROR"
    end
end

Galdur.add_new_page({
    name = 'gald_draft_mode', -- this name is displayed on the next page button
    definition = deck_select_page_draft_mode,
    pre_start = function()

    end,
    post_start = function()

    end,
    confirm = function()

    end,
    quick_start_text = quick_start_text
})

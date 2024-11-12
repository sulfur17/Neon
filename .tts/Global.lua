--require("Common")

--#region Const

TABLE_TOKEN_TAG = 'TableToken'
FIGHTER_TOKEN_TAG = 'FighterToken'
BOT_TAG = 'Bot'
SEARCH_TOKEN_TAG = 'SearchToken'
LIFT_HEIGHT = 3
TIME_TO_MOVE_SECTORS = 1

SectorsList = nil
SectorOrder = nil
TableOrder = nil
Sectors = nil
Started = false

--#endregion

--#region Events

function onLoad(script_state)
    math.randomseed(os.time())

    local state, loaded = LoadedState(script_state)
    if loaded then
        Started = state.Started
    end

    Init()

    HighlightFightersTokens()
end

function onSave()
    local state = {
        Started = Started
    }
    return JSON.encode(state)
end

--#endregion

--#region Commands

function btnStart(player, click, id)
    if click ~= '-1' then return end -- pressed not with LMB

    Started = true

    TableOrder = ShuffledList(SectorsList)
    PlaceTableTokens(TableOrder)
    SectorOrder = ShuffledList(SectorsList)
    PlaceSectors(SectorOrder)
    PlaceBots(SectorsList)

    CreateSearchButtons()

    UpdateUI()
end

function CreateSearchButtons()
    for _,sector in ipairs(Sectors) do
        sector.createButton({
            click_function = 'btnSearch',
            label = 'Поиск',
            position = {x=0, y=0, z=-2},
            rotation = {x=0, y=0, z=0},
            scale = {x=0.5, y=1, z=0.5},
            width = 600,
            height = 250,
            font_size = 160,
        })
    end
end

function btnSearch(sector, player_clicker_color, alt_click)
    if alt_click then return end -- pressed not with LMB

    local set = SetFromNotes(sector.getGMNotes())
    if     set.Loot == '1' then

        Decks.Loot.Green.deal(3, player_clicker_color)

    elseif set.Loot == '2' then

        Decks.Loot.Orange.deal(2, player_clicker_color)

    elseif set.Loot == '3' then

        Decks.Loot.Green.deal(1, player_clicker_color)
        Decks.Loot.Purple.deal(1, player_clicker_color)

    end

    if set.N == '6' then -- В торговом центре на 1 оранжевую больше
        Decks.Loot.Orange.deal(1, player_clicker_color)
    end

    SearchTokenBag.takeObject({position=sector.getPosition()+Vector(0,1,0), rotation=sector.getRotation()})

end

function btnNextRound(player, click, id)
    if click ~= '-1' then return end -- pressed not with LMB

    local objectsOnSectors = ObjectsOnSectors(getObjects())

    local tableTokens = GetObjectsByProperty(RoundsSheetZone.getObjects(), {tag=TABLE_TOKEN_TAG})

    local prevOrder = CopyTable(SectorOrder)

    local lifted = {}
    for _,token in ipairs(tableTokens) do
        local n = tonumber(token.getGMNotes())

        local sector = Sectors[n]
        if sector then
            for _,obj in ipairs(LiftObjectsOnSector(n, objectsOnSectors)) do
                lifted[obj] = n
            end

            DeleteSector(n)
        end
    end

    log(lifted)
    AttachObjectsToSectors(objectsOnSectors, lifted)

    PlaceSectors(SectorOrder)

    PlaceLifted(lifted, prevOrder, SectorOrder)

    Wait.time(RemoveAttachmentsFromSectors, TIME_TO_MOVE_SECTORS)

end

function onObjectSpawn(obj)
    HighlightFighterToken(obj)
end

function test(player, click, id)
    if click ~= '-1' then return end -- pressed not with LMB
    print('test')
end

--#endregion

function Init()
    Tokens = {
        Table = {
            getObjectFromGUID('646edb'),
            getObjectFromGUID('4eac3d'),
            getObjectFromGUID('da7dca'),
            getObjectFromGUID('cc1035'),
            getObjectFromGUID('2e9c36'),
            getObjectFromGUID('f8d30a'),
            getObjectFromGUID('d5ac22'),
            getObjectFromGUID('3bea0a'),
            getObjectFromGUID('8c061b'),
            getObjectFromGUID('58b7ed'),
        }
    }
    SectorsList = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10}
    Sectors = {
        getObjectFromGUID('f57542'),
        getObjectFromGUID('c35477'),
        getObjectFromGUID('5292ca'),
        getObjectFromGUID('33c440'),
        getObjectFromGUID('c7d737'),
        getObjectFromGUID('d4906f'),
        getObjectFromGUID('b78432'),
        getObjectFromGUID('d6facf'),
        getObjectFromGUID('1e60fd'),
        getObjectFromGUID('15d7af'),
    }
    RoundsSheet = getObjectFromGUID('6fddde')
    BotsContainer = getObjectFromGUID('ca0fdd')
    LandingShip = getObjectFromGUID('e36ee2')
    RoundsSheetZone = getObjectFromGUID('297069')
    SearchTokenBag = getObjectFromGUID('c0d57e')
    Decks = {
        Loot = {
            Green  = getObjectFromGUID('bb4db8'),
            Orange = getObjectFromGUID('4a47be'),
            Purple = getObjectFromGUID('8afbdf'),
        }
    }
    FighterColors = {
        ['Глыба']   = 'Orange',
        ['Призрак'] = 'White',
        ['Феникс']  = 'Red',
        ['Акари']   = 'Pink',
        ['Снейк']   = 'Green',
        ['Иллюзия'] = 'Teal',
    }
end

function UpdateUI()
    LandingShip.UI.setAttribute('start', 'active', not Started)
end

function LiftObjectsOnSector(sectorID, objectsOnSectors)
    local lifted = {}
    local objects = objectsOnSectors[Sectors[sectorID]]
    for _,obj in pairs(objects) do
        if obj.hasTag(FIGHTER_TOKEN_TAG) then
            --obj.lock()
            --local v = obj.getPosition()
            --obj.setPositionSmooth(v + v)
            --MoveSmooth(obj, {y=LIFT_HEIGHT})
            table.insert(lifted, obj)
        end
    end
    return lifted
end

function MovableObject(obj)

    local tags = {FIGHTER_TOKEN_TAG, BOT_TAG, SEARCH_TOKEN_TAG}
    for _,tag in ipairs(tags) do
        if obj.hasTag(tag) then
            return true
        end
    end
    return false
end

function ObjectsOnSectors(objects)

    local res = {}
    for _,sec in pairs(Sectors) do
        res[sec] = {}
    end

    for _,obj in ipairs(objects) do
        if MovableObject(obj) then
            local n = obj.getName()
            --local n = obj.Nickname
            local hitlist = Physics.cast({
                origin = obj.getPosition()+Vector(0, 0.5, 0),
                direction = Vector(0, -1, 0),
                type = 1,
                max_distance = 2,
                debug = false,
            })

            local sector = ObjectIsOnSector(hitlist)
            if sector then
                table.insert(res[sector], obj)
            end
        end
    end

    return res
end

function ObjectIsOnSector(hitlist)
    for _,tab in ipairs(hitlist) do
        if ValueIsInTable(tab.hit_object, Sectors) then
            return tab.hit_object
        end
    end
    return nil
end

function PlaceTableTokens(list)
    for i,n in ipairs(list) do
        local token = Tokens.Table[n]
        token.setPosition(Vector(0, 2 + tonumber(i)*0.3, 0))
    end
end

function PlaceSectors(list)

    local r = 10

    local angleStep = 360 / #list -- angle step
    local y = Sectors[list[1]].getPosition().y
    --local scale = 2.5
    local angle = 0
    for _,n in pairs(list) do
        local sector = Sectors[n]
        local z = math.cos(math.rad(angle)) * r
        local x = math.sin(math.rad(angle)) * r
        --sector.setScale({scale, 0, scale})
        sector.setPositionSmooth(Vector(x, y, z))
        sector.setRotationSmooth(Vector(0, angle, 0))
        angle = angle + angleStep
    end
end

function PlaceLifted(lifted, prevOrder, newOrder)
    local amount = {}
    local r = 16
    local angleStep = 360 / #newOrder -- angle step
    local y = 2 --Sectors[list[1]].getPosition().y
    for obj,n in pairs(lifted) do
        local place = LiftPlace(n, prevOrder, newOrder)
        if amount[place] then
            amount[place] = amount[place] + 1
        else
            amount[place] = 0
        end
        local angle = angleStep * (place - 0.5)
        local z = math.cos(math.rad(angle)) * (r + amount[place]*1.5)
        local x = math.sin(math.rad(angle)) * (r + amount[place]*1.5)
        obj.setPositionSmooth(Vector(x, y + amount[place], z))
    end

end

function LiftPlace(prevN, prevOrder, newOrder)
    local res = #newOrder
    for i,n in ipairs(prevOrder) do
        local k = ValueIsInTable(n, newOrder)
        if k then
            res = k
        end
        if n == prevN then
            return res
        end
    end
end

function PlaceBots(list)
    BotsContainer.shuffle()
    for i,n in ipairs(list) do
        local sector = Sectors[n]
        BotsContainer.takeObject({position=sector.getPosition() + Vector(0, 1, 0), rotation=sector.getRotation()})
    end
end

function AttachObjectsToSectors(tab, except)
    for sec, objs in pairs(tab) do
        if objs and #objs > 0 then
            for _,obj in ipairs(objs) do
                if not except[obj] then
                    obj.setPosition(obj.getPosition() + Vector(0,1,0))
                    sec.addAttachment(obj)
                end
            end
        end
    end
end

function RemoveAttachmentsFromSectors()
    for _,sec in pairs(Sectors) do
        sec.removeAttachments()
    end
end

function DeleteSector(n)
    local sector = Sectors[n]
    if sector then
        sector.destruct()
        SectorOrder = RemoveValueFromList(SectorOrder, n)
        Sectors[n] = nil
    end
end

function HighlightFightersTokens()
    local tokens = getObjectsWithTag(FIGHTER_TOKEN_TAG)
    for _,obj in ipairs(tokens) do
        HighlightFighterToken(obj)
    end
end

function HighlightFighterToken(obj)
    if not (obj.type == 'Tile' and obj.hasTag(FIGHTER_TOKEN_TAG)) then
        return
    end
    local color = Color.fromString(FighterColors[obj.getName()])
    obj.highlightOn(color)
end

require("Common")
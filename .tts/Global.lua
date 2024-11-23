--[[ TODO

сброс вещей
куда урон класть
нужно порядок хода
сторона Б не удобная
как обозначить что боеприпас использован
колоды вещей восстанавливать
можно ли использовать несколько боеприпасов
нельзя брать боеприпас
автоподсчет очков
запускать музыку

режимы:
возрождение
королевская битва
коалиция
автома
]]


--#region Const

TABLE_TOKEN_TAG = 'TableToken'
FIGHTER_TOKEN_TAG = 'FighterToken'
BOT_TAG = 'Bot'
SEARCH_TOKEN_TAG = 'SearchToken'
READY_TOKEN_TAG = 'ReadyToken'
ACTION_CARD_TAG = 'ActionCard'
LIFT_HEIGHT = 3
TIME_TO_MOVE_SECTORS = 1

SectorsList = nil
SectorOrder = nil
Sectors = nil
Started = false
Moved = {}

--#endregion

--#region Events

function onLoad(script_state)
    math.randomseed(os.time())

    Init()

    local state, loaded = LoadedState(script_state)
    if loaded then
        Started = state.Started
        SectorOrder = state.SectorOrder
        Moved = state.Moved
    end

    HighlightFightersTokens()
end

function onSave()
    local state = {
        Started = Started,
        SectorOrder = SectorOrder,
        Moved = Moved,
    }
    return JSON.encode(state)
end

function onPlayerTurn(player, previous_player)
    if previous_player and Moved then
        Moved[previous_player.color] = true
        if not ValueIsInTable(false, Moved) then
            Turns.enable = false
        end
    end
end

function onObjectSpawn(obj)
    HighlightFighterToken(obj)
end

--#endregion

--#region Commands

function btnStart(player, click, id)
    if click ~= '-1' then return end -- pressed not with LMB

    Started = true

    local tableOrder = ShuffledList(SectorsList)
    PlaceTableTokens(tableOrder)
    SectorOrder = ShuffledList(SectorsList)
    PlaceSectors(SectorOrder)
    PlaceBots(SectorsList)

    CreateSearchButtons()

    UpdateUI()

    Decks.Loot.Green.shuffle()
    Decks.Loot.Orange.shuffle()
    Decks.Loot.Purple.shuffle()
    Decks.Improvement.shuffle()
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

    local toClose = MoveTableTokensToSheet(id)

    CloseSectors(toClose)

    SetupReadyTokens()

    TurnOffShields()

    Turns.enable = false

end

function btnGetLeadership(player, click, id)
    if click ~= '-1' then return end -- pressed not with LMB

    local fighter = KeyByValue(Fighter.Colors, player.color)
    local pos = Fighter.Sheets[fighter].getPosition()
    Tokens.Leader.setPositionSmooth(pos + Vector(-2, 1, 0))

    Wait.time(function ()
        Turns.order = GetTurnOrder()
        log(Turns.order)
    end, 1) -- time to get leadership token

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
        },
        Leader = getObjectFromGUID('0b9a2b')
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
    BotsContainer = getObjectFromGUID('ca0fdd')
    LandingShip = getObjectFromGUID('e36ee2')
    SearchTokenBag = getObjectFromGUID('c0d57e')
    Decks = {
        Loot = {
            Green  = getObjectFromGUID('bb4db8'),
            Orange = getObjectFromGUID('4a47be'),
            Purple = getObjectFromGUID('8afbdf'),
        },
        Improvement = getObjectFromGUID('9709a7'),
    }
    Fighter = {
        Colors = {
            ['Глыба']   = 'Orange',
            ['Призрак'] = 'White',
            ['Феникс']  = 'Red',
            ['Акари']   = 'Pink',
            ['Снейк']   = 'Green',
            ['Иллюзия'] = 'Teal',
        },
        Sheets = {
            ['Глыба']   = getObjectFromGUID('7e758f'),
            ['Призрак'] = getObjectFromGUID('5addbf'),
            ['Феникс']  = getObjectFromGUID('8136a5'),
            ['Акари']   = getObjectFromGUID('b41dd1'),
            ['Снейк']   = getObjectFromGUID('9bf9ca'),
            ['Иллюзия'] = getObjectFromGUID('c6bcdc'),
        }
    }
    ColorsOrder = {'Pink', 'Orange', 'White', 'Red', 'Green', 'Teal'}
    Zones = {
        ChoosedCards = {
            Teal   = getObjectFromGUID('9e51ff'),
            Green  = getObjectFromGUID('1045c8'),
            Red    = getObjectFromGUID('dc192a'),
            White  = getObjectFromGUID('cfed5c'),
            Orange = getObjectFromGUID('4597bf'),
            Pink   = getObjectFromGUID('125296'),
        }
    }
    LeaderToken = getObjectFromGUID('0b9a2b')
    TableTokensZone = getObjectFromGUID('56882d')
    RoundsInfo = {
        Sheet = getObjectFromGUID('6fddde'),
        Zone = getObjectFromGUID('297069'),
        Positions = {
            Vector(   0, 2,  2.1),
            Vector( 1.7, 2,  1.0),
            Vector( 1.7, 2, -1.0),
            Vector(   0, 2, -2.1),
            Vector(-1.7, 2, -1.0),
            Vector(-1.7, 2,  1.0),
            Vector(   0, 2,  0),
        },
        ['2-4'] = {2, 2, 1, 2, 1, 2},
        ['5-6'] = {1, 2, 1, 2, 1, 1, 2},
    }
end

function UpdateUI()
    LandingShip.UI.setAttribute('start', 'active', not Started)
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

function LiftFightersOnSectors(numbers, objectsOnSectors)
    local lifted = {}
    for _,n in ipairs(numbers) do
        for _,obj in ipairs(LiftFightersOnSector(n, objectsOnSectors)) do
            lifted[obj] = n
        end
    end
    return lifted
end

function LiftFightersOnSector(n, objectsOnSectors)
    local lifted = {}
    local objects = objectsOnSectors[Sectors[n]]
    for _,obj in pairs(objects) do
        if obj.hasTag(FIGHTER_TOKEN_TAG) then
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

    if #list == 0 then
        return
    end

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
        if sec then
            if objs and #objs > 0 then
                for _,obj in ipairs(objs) do
                    if obj and not except[obj] then
                        obj.setPosition(obj.getPosition() + Vector(0,1,0))
                        sec.addAttachment(obj)
                    end
                end
            end
        end
    end
end

function RemoveAttachmentsFromSectors()
    for _,n in pairs(SectorOrder) do
        local sector = Sectors[n]
        sector.removeAttachments()
    end
end

-- Удаляет все жетоны с секторов кроме бойцов
function DeleteUnwantedObjects(sectorNumbers, objectsOnSectors)
    for _,n in ipairs(sectorNumbers) do
        local objectsList = objectsOnSectors[Sectors[n]]
        for _,obj in ipairs(objectsList) do
            if not obj.hasTag(FIGHTER_TOKEN_TAG) then
                obj.destroy()
            end
        end
    end
end

function DeleteSectors(sectorNumbers, objectsOnSectors)
    for _,n in ipairs(sectorNumbers) do
        local sector = Sectors[n]
        if sector then
            objectsOnSectors[sector] = nil
            sector.destruct()
            SectorOrder = RemoveValueFromList(SectorOrder, n)
            --Sectors[n] = nil
        end
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
    local color = Color.fromString(Fighter.Colors[obj.getName()])
    obj.highlightOn(color)
end

function SetupReadyTokens()
    local tokens = getObjectsWithTag(READY_TOKEN_TAG)
    for _,obj in ipairs(tokens) do
        SetFaceUpSmooth(obj, '+')
    end
end

function CurrentRound(players)
    local tokens = RoundsInfo.Zone.getObjects()
    tokens = GetObjectsByProperty(tokens, {tag=TABLE_TOKEN_TAG})
    local round = 1
    local rest = #tokens
    local tokensAmound = CopyTable(RoundsInfo[players])
    for _,n in ipairs(tokensAmound) do
        if rest > 0 then
            rest = rest - n
            round = round + 1
        else
            return round
        end
    end
    return round
end

function TopTableTokens(amount)
    local order = {}
    local tokens = TableTokensZone.getObjects()
    tokens = GetObjectsByProperty(tokens, {tag=TABLE_TOKEN_TAG})

    local yy = {}
    for _,token in ipairs(tokens) do
        local y = token.getPosition().y
        order[y] = token
        table.insert(yy, y)
    end

    table.sort(yy, function (a, b) return (a > b) end)

    local top = {}
    for i=1,amount do
        local token = order[yy[i]]
        table.insert(top, token)
    end

    return top
end

function MoveTableTokensToSheet(roundsSheetSide)

    local round = CurrentRound(roundsSheetSide)
    local tokensAmount = RoundsInfo[roundsSheetSide][round]
    local vector = RoundsInfo.Positions[round]
    local position = RoundsInfo.Sheet.getPosition() + vector
    local tokens = TopTableTokens(tokensAmount)
    for i,token in ipairs(tokens) do
        token.setPositionSmooth(position + Vector(0, i, 0))
    end

    local toClose = {}
    for _,token in ipairs(tokens) do
        local n = tonumber(token.getGMNotes())
        table.insert(toClose, n)
    end

    return toClose
end

function AdjecentSectorIDs(number)
    local res_i = KeyByValue(SectorOrder, number) - 1
    local prev = (res_i + #SectorOrder - 1) % #SectorOrder + 1
    local next = (res_i + #SectorOrder + 1) % #SectorOrder + 1
    return {SectorOrder[prev], SectorOrder[next]}
end

function DeleteSearchTokenOnSector(tokens)

    if #tokens == 0 then
        return
    end

    local token = tokens[1]
    token.destruct()
    table.remove(tokens, 1)
    return token
end

function DeleteSearchTokensOnAdjecentSectors(searchTokensOnSectors, sectorIDs)
    local deleted = {}

    for _,main_id in ipairs(sectorIDs) do
        local adjecentSectorsIDs = AdjecentSectorIDs(main_id)

        for _,id in ipairs(adjecentSectorsIDs) do
            local sector = Sectors[id]
            local token = DeleteSearchTokenOnSector(searchTokensOnSectors[sector])
            if deleted[sector] then
                table.insert(deleted[sector], token)
            else
                deleted[sector] = {token}
            end
        end
    end

    return deleted
end

function ExcludeDeleted(objectsOnSectors, deleted)
    for sec,objects in pairs(deleted) do
        for _,obj in ipairs(objects) do
            objectsOnSectors[sec] = RemoveValueFromList(objectsOnSectors[sec], obj)
        end
    end
end

function CloseSectors(toClose)

    local prevOrder = CopyTable(SectorOrder)

    local searchTokensOnSectors = ObjectsOnPlaces(getObjectsWithTag(SEARCH_TOKEN_TAG), Sectors)
    local deleted = DeleteSearchTokensOnAdjecentSectors(searchTokensOnSectors, toClose)

    local objectsOnSectors = ObjectsOnPlaces(getObjects(), Sectors)
    ExcludeDeleted(objectsOnSectors, deleted)

    local lifted = LiftFightersOnSectors(toClose, objectsOnSectors)

    DeleteUnwantedObjects(toClose, objectsOnSectors)

    DeleteSectors(toClose, objectsOnSectors)

    Wait.frames(function()

        AttachObjectsToSectors(objectsOnSectors, lifted)

        PlaceSectors(SectorOrder)

        PlaceLifted(lifted, prevOrder, SectorOrder)

        Wait.time(RemoveAttachmentsFromSectors, TIME_TO_MOVE_SECTORS)

    end, 10) -- time to destruct unwanted tokens

end

function TurnOffShields()
    local fighters = getObjectsWithTag(FIGHTER_TOKEN_TAG)
    for _,obj in ipairs(fighters) do
        if obj.getStateId() ~= 1 then
            obj.setState(1)
        end
    end
end

function GetLeader()
    local res

    local distance = 999
    for name,sheet in pairs(Fighter.Sheets) do
        local newDistance = Vector.distance(sheet.getPosition(), LeaderToken.getPosition())
        if newDistance < distance then
            distance = newDistance
            res = Fighter.Colors[name]
        end
    end

    return res
end

function GetInitiatives()
    local res = {}

    for color,zone in pairs(Zones.ChoosedCards) do

        local max_y = -10
        local topCard = nil
        local objects = zone.getObjects()
        for _,obj in ipairs(objects) do
            if obj.type == 'Card' and obj.hasTag(ACTION_CARD_TAG) then
                local card = obj
                local newY = card.getPosition().y
                if newY > max_y then
                    topCard = card
                    max_y = newY
                end
            end
        end
        if topCard then
            local initiative = tonumber(topCard.getGMNotes())
            res[color] = initiative
        end
    end

    return res
end

function GetTurnOrder()
    local res = {}

    local leader = GetLeader()
    local order = SortByPlayer(ColorsOrder, leader)
    local initiatives = GetInitiatives()

    for i = 1,7 do
        for _,color in ipairs(order) do
            if initiatives[color] == i then
                if not Moved[color] then
                    table.insert(res, color)
                end
            end
        end
    end

    return res
end

function StartPlayersActions()

    -- TODO: set shields
    Turns.order = GetTurnOrder()
    Turns.enable = true

    Moved = {}
    for _,color in ipairs(Turns.order) do
        Moved[color] = false
    end

end

require("Common")
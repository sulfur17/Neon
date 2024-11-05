--require("Common")

--#region Const

TABLE_TOKEN_TAG = 'TableToken'

SectorsList = nil
SectorOrder = nil
TableOrder = nil
Sectors = nil

--#endregion

--#region Events
function onLoad(script_state)
    math.randomseed(os.time())

    Init()
end

function onSave()
end

--#endregion

--#region Commands

function btnStart(player, click, id)
    if click ~= '-1' then return end -- pressed not with LMB

    LandingShip.UI.setAttribute(id, 'active', false)

    TableOrder = ShuffledList(SectorsList)
    PlaceTableTokens(TableOrder)
    SectorOrder = ShuffledList(SectorsList)
    PlaceSectors(SectorOrder)
    PlaceBots(SectorsList)

end

function btnNextRound(player, click, id)
    if click ~= '-1' then return end -- pressed not with LMB

    local tokens = GetObjectsByProperty(RoundsSheetZone.getObjects(), {tag=TABLE_TOKEN_TAG})
    for _,token in ipairs(tokens) do
        local n = tonumber(token.getGMNotes())
        DeleteSector(n)
    end

    local tab = ObjectsOnSectors(getObjects())
    AttachObjectsToSectors(tab)

    PlaceSectors(SectorOrder)

    Wait.time(RemoveAttachmentsFromSectors, 1)

end

function RemoveAttachmentsFromSectors()
    for _,sec in pairs(Sectors) do
        sec.removeAttachments()
    end
end

function AttachObjectsToSectors(tab)
    for sec, objs in pairs(tab) do
        if #objs > 0 then
            for _,obj in ipairs(objs) do
                sec.addAttachment(obj)
            end
        end
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


function test(player, click, id)
    if click ~= '-1' then return end -- pressed not with LMB
    print('test')
end

function ObjectsOnSectors(objects)

    local res = {}
    for _,sec in pairs(Sectors) do
        res[sec] = {}
    end

    for _,obj in ipairs(objects) do
        local hitlist = Physics.cast({
            origin = obj.getPosition(),
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
        Bots = {
            getObjectFromGUID(''),
            getObjectFromGUID(''),
            getObjectFromGUID(''),
            getObjectFromGUID(''),
            getObjectFromGUID(''),
            getObjectFromGUID(''),
            getObjectFromGUID(''),
            getObjectFromGUID(''),
            getObjectFromGUID(''),
            getObjectFromGUID(''),
        },
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
end

function PlaceTableTokens(list)
    for i,n in ipairs(list) do
        local token = Tokens.Table[n]
        token.setPosition(Vector(0, 2 + tonumber(i)*0.3, 0))
    end
end

function PlaceSectors(list)

    local r = ({
        [10] = 10,
        [9]  = 9.5,
        [8]  = 9,
        [7]  = 8.5,
        [6]  = 8,
    })[math.max(#list, 6)]

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

function PlaceBots(list)
    BotsContainer.shuffle()
    for i,n in ipairs(list) do
        local sector = Sectors[n]
        BotsContainer.takeObject({position=sector.getPosition() + Vector(0, 1, 0), rotation=sector.getRotation()})
    end
end

require("Common")
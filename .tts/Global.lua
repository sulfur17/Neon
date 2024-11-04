--require("Common")

--#region Variables

--#endregion

--#region Events
function onLoad()
    math.randomseed(os.time())

    Init()
end

function onSave()
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
end

function PlaceTableTokens()
    for i,token in ipairs(Tokens.Table) do
        token.setPosition(Vector(0, 1+tonumber(i), 0))
    end
end

function PlaceSectors(list)

    local r = ({
        [10] = 10,
        [9]  = 9.5,
        [8]  = 9,
        [7]  = 8.5,
        [6]  = 8,
    })[#list]

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
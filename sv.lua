-- version check
Citizen.CreateThread(function()
    local vRaw = LoadResourceFile(GetCurrentResourceName(), 'version.json')
    if vRaw and config.versionCheck then
        local v = json.decode(vRaw)
        local url = 'https://raw.githubusercontent.com/DevBlocky/nearest-postal/master/version.json'
        PerformHttpRequest(url, function(code, res)
            if code == 200 then
                local rv = json.decode(res)
                if rv.version ~= v.version then
                    print(([[
-------------------------------------------------------
nearest-postal
UPDATE: %s AVAILABLE
CHANGELOG: %s
-------------------------------------------------------
]]):format(rv.version, rv.changelog))
                end
            else
                print('nearest-postal was unable to check the version')
            end
        end, 'GET')
    end
end)

-- add functionality to get postals server side from a vec3

local postals = nil
Citizen.CreateThread(function()
    postals = LoadResourceFile(GetCurrentResourceName(), GetResourceMetadata(GetCurrentResourceName(), 'postal_file'))
    postals = json.decode(postals)
    for i, postal in ipairs(postals) do
        postals[i] = {vec(postal.x, postal.y), code = postal.code}
    end
end)

local function getPostalServer(coords)
    while postals == nil do
        Wait(1)
    end
    local _total = #postals
    local _nearestIndex, _nearestD
    coords = vec(coords[1], coords[2])

    for i = 1, _total do
        local D = #(coords - postals[i][1])
        if not _nearestD or D < _nearestD then
            _nearestIndex = i
            _nearestD = D
        end
    end
    local _code = postals[_nearestIndex].code
    local nearest = {code = _code, dist = _nearestD}
    return nearest or nil
end

exports('getPostalServer', function(coords)
    return getPostalServer(coords)
end)

if config.useEsx then
    ESX = exports["es_extended"]:getSharedObject()

    local currentPositions = LoadResourceFile(GetCurrentResourceName(), GetResourceMetadata(GetCurrentResourceName(), 'postal_file'))
    local currentPositions = json.decode(currentPositions)

    ESX.RegisterCommand('plog', 'admin', function(xPlayer, args, showError)
        local coords = xPlayer.getCoords(false)

        if not args.postal then print('A postal is required!') return end
        
        postNum = tonumber(args.postal)

        if (postNum >= 1) and (postNum <= 9) then
            tostring(postNum)
            postal = '00' .. postNum
        elseif (postNum >= 10) and (postNum <= 99) then
            tostring(postNum)
            postal = '0' .. postNum
        elseif postNum >= 100 then
            tostring(postNum)
            postal = postNum
        end
        
        convPostal = tostring(postal)

        currentPositions[#currentPositions + 1] = {code = convPostal, x = coords.x, y = coords.y}
        SaveResourceFile(GetCurrentResourceName(), "postals.json", json.encode(currentPositions), -1)
        print("^5[Obtain Position]^7 ^2Successfully saved positions to JSON file!^7")
        print(("^3[Postals Saved!] Postal: %s | X: %s, Y: %s^7"):format(convPostal, coords.x, coords.y))
        print("^5[File Backup]^7 ^2Be sure to backup your postals.json file before the next server restart to save your work!^7")

    end, false, {help = 'Captures and stores postal with X/Y coords in a table.', arguments = {{name = 'postal', help = 'Postal for captured coordinates', type = 'any'}}})    
end

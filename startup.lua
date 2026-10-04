-- Contrôle d'accès par badge RFID (Classic Peripherals)
-- À enregistrer sous le nom "startup.lua" pour un lancement automatique au démarrage.

local FICHIER_BADGES = "badges.db"   -- fichier contenant la table des badges
local DISTANCE_MIN   = 2             -- distance minimale (blocs)
local DISTANCE_MAX   = 4             -- distance maximale (blocs)
local COTE_PORTE     = "top"         -- côté de sortie redstone (haut du PC)
local PUISSANCE      = 15            -- puissance du signal redstone
local DUREE_OUVERTE  = 5             -- secondes pendant lesquelles la porte reste ouverte
local INTERVALLE     = 0.5           -- secondes entre deux scans

-- 1) Création du fichier de badges (une seule fois)
if not fs.exists(FICHIER_BADGES) then
    local badgesParDefaut = {
        "badge_admin",   -- <-- remplacez par les données réelles de vos badges
        "badge_invite",
    }
    local f = fs.open(FICHIER_BADGES, "w")
    f.write(textutils.serialise(badgesParDefaut))
    f.close()
    print("Fichier '" .. FICHIER_BADGES .. "' cree avec des badges par defaut.")
else
    print("Fichier '" .. FICHIER_BADGES .. "' deja present, conservation.")
end

-- Chargement de la table des badges
local function chargerBadges()
    local f = fs.open(FICHIER_BADGES, "r")
    if not f then return {} end
    local contenu = f.readAll()
    f.close()
    local table_ = textutils.unserialise(contenu)
    if type(table_) ~= "table" then return {} end
    -- Transformation en ensemble pour une recherche rapide
    local set = {}
    for _, data in ipairs(table_) do set[data] = true end
    return set
end

-- 2) Vérification de la présence du scanner RFID après le démarrage
local scanner = peripheral.find("rfid_scanner")
while not scanner do
    term.clear()
    term.setCursorPos(1, 1)
    print("ERREUR : aucun scanner RFID connecte.")
    print("Nouvelle verification dans 3 secondes...")
    sleep(3)
    scanner = peripheral.find("rfid_scanner")
end

term.clear()
term.setCursorPos(1, 1)
print("Scanner RFID detecte.")
print("Zone de lecture : " .. DISTANCE_MIN .. " a " .. DISTANCE_MAX .. " blocs.")
print("En attente de badges...")

redstone.setAnalogOutput(COTE_PORTE, 0)

-- 3) Boucle principale
while true do
    local badges = chargerBadges()   -- rechargé à chaque tour : modifications prises en compte
    local ok, resultats = pcall(scanner.scan)

    if not ok then
        print("Scanner perdu, nouvelle recherche...")
        redstone.setAnalogOutput(COTE_PORTE, 0)
        repeat
            sleep(2)
            scanner = peripheral.find("rfid_scanner")
        until scanner
    else
        for _, badge in ipairs(resultats) do
            if badge.distance >= DISTANCE_MIN and badge.distance <= DISTANCE_MAX
               and badges[badge.data] then
                print(("Badge valide (%.1f blocs) : porte ouverte."):format(badge.distance))
                redstone.setAnalogOutput(COTE_PORTE, PUISSANCE)
                sleep(DUREE_OUVERTE)
                redstone.setAnalogOutput(COTE_PORTE, 0)
                print("Porte refermee.")
                break
            end
        end
    end

    sleep(INTERVALLE)
end

-------------
-- Options --
-------------
options.timeout = 120
options.subscribe = true
options.create = true
options.limit = 50

-- Helper to find script path
local function script_path()
  local str = debug.getinfo(2, "S").source:sub(2)
  return str:match("(.*/)")
end

-- Last inn avhengigheter én gang for å unngå I/O-operasjoner i løkker
local base_path = script_path()
dofile(base_path .. 'accounts.lua')
dofile(base_path .. 'filters.lua')

-- Filter mailing lists dynamically via RFC 2919 List-Id header
local function filter_dynamic_lists(account)
  local results = account.INBOX:contain_field('List-Id', '.')

  -- Returner umiddelbart hvis resultatsettet er tomt
  if #results == 0 then return end

  -- Henter alle List-Id headere for resultatsettet i én operasjon
  local headers = account.INBOX:fetch_header(results, 'List-Id')
  local messages_by_folder = {}

  for _, mesg in ipairs(results) do
    local uid = mesg[2]
    -- Henter header fra den forhåndslastede tabellen
    local header = headers[uid] or headers[tostring(uid)] or ""

    -- Trekker ut verdien mellom vinkelparentesene
    local list_id = string.match(header, "<([^>]+)>")

    if list_id then
      -- Bytter ut punktum og alfakrøll med bindestrek for sikre mappenavn
      local clean_name = string.gsub(list_id, "[%.@]", "-")
      local folder_name = "lists-" .. clean_name

      if not messages_by_folder[folder_name] then
        messages_by_folder[folder_name] = {}
      end

      table.insert(messages_by_folder[folder_name], mesg)
    end
  end

  -- Utfører bulk-flytting per mappe
  for folder, msgs in pairs(messages_by_folder) do
    Set(msgs):move_messages(account[folder])
  end
end

-- Filter anoying news letters
local function filter_newsletter(account)
  local results = account.INBOX:contain_from("newsletter") +
                  account.INBOX:contain_from("nyhetsbrev") +
                  account.INBOX:contain_subject("newsletter") +
                  account.INBOX:contain_subject("nyhetsbrev") +
                  account.INBOX:contain_body("newsletter") +
                  account.INBOX:contain_body("nyhetsbrev")
  results:move_messages(account['misc-newsletter'])
end

-- Filter anoying webinars.
local function filter_webinar(account)
  local results = account.INBOX:contain_from("webinar") +
                  account.INBOX:contain_subject("webinar") +
                  account.INBOX:contain_body("webinar")
  results:move_messages(account['misc-webinar'])
end

-- Normal filters on from address
local function filter_from(account, address, folder)
  local results = account.INBOX:contain_from(address) +
                  account.INBOX:contain_cc(address) +
                  account.INBOX:contain_to(address)
  results:move_messages(account[folder])
end

-- Run filters on all accounts
for _, account in pairs(accounts) do
  -- Automatisk identifisering og ruting av mailinglister
  filter_dynamic_lists(account)

  -- Prosesserer manuelle regler for avsendere
  for address, folder in pairs(from_to_cc_folder) do
    filter_from(account, address, folder)
  end

  filter_webinar(account)
  filter_newsletter(account)
end

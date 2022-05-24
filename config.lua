-------------
-- Options --
-------------

options.timeout = 120
options.subscribe = true
options.create = true
options.limit = 50

-- Helper to find script path
function script_path()
  local str = debug.getinfo(2, "S").source:sub(2)
  return str:match("(.*/)")
end

-- Accounts to run filters on, use accounts.lua.template as your base for accounts.lua
dofile(script_path() .. '/accounts.lua')

-- Filter mailing lists
function filter_lists(account, address)
  results = account.INBOX:contain_field('X-Mailing-List', address) +
            account.INBOX:contain_cc(address) +
            account.INBOX:contain_to(address)

  -- Put mailing list in lists/ folder named mailing list address
  -- e.g. 'lists-ubuntu-announce'
  list = string.gmatch(address, '[%w%-]+')
  results:move_messages(account['lists-' .. list()])
end

-- Filter anoying news letters, this filters English and Norwegian.
-- Modify for your own language.
function filter_newsletter(account)
  results = account.INBOX:contain_from("newsletter") +
            account.INBOX:contain_from("nyhetsbrev") +
            account.INBOX:contain_subject("newsletter") +
            account.INBOX:contain_subject("nyhetsbrev") +
            account.INBOX:contain_body("newsletter") +
            account.INBOX:contain_body("nyhetsbrev")
  results:move_messages(account['misc-newsletter'])
end

-- Filter anoying webinars.
function filter_webinar(account)
  results = account.INBOX:contain_from("webinar") +
            account.INBOX:contain_subject("webinar") +
            account.INBOX:contain_body("webinar")
  results:move_messages(account['misc-webinar'])
end

-- Normal filters on from address
function filter_from(account, address, folder)
  results = account.INBOX:contain_from(address) +
            account.INBOX:contain_cc(address) +
            account.INBOX:contain_to(address)
  results:move_messages(account[folder])
end

-- Run filters on all accounts
for _, account in pairs(accounts) do

  -- See filters.lua.template how to create your own filters.lua
  dofile(script_path() .. '/filters.lua')
  for _, address in pairs(list_addresses) do
    filter_lists(account, address)
  end

  for address, folder in pairs(from_to_cc_folder) do
    filter_from(account, address, folder)
  end

  filter_webinar(account)
  filter_newsletter(account)
end

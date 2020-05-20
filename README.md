# imapfilter

* `config.lua` --- main `imapfilter` config.
* `accounts.lua` --- split out account settings, use `accounts.lua.template` as base.
* `filters.lua` --- split out filters as lua tables, use `filters.lua.template` as base.

## crontab

Example below runs every five minute, and log every output from `imapfilter` to the journal.

1. Edit user cron.
    ```bash
    crontab -e
    ```
0. Add crontab entry.
    ```cron
    */5 * * * * bash -c 'imapfilter 2>&1 | systemd-cat -t IMAPFILTER'
    ```

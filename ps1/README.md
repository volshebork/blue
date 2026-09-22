# Recommended Run Order

1. `get_privileged_groups.ps1`
2. `get_current_services.ps1`
3. `get_event_7045.ps1`
4. `get_current_scheduledtask_creation_dates.ps1`
5. `get_event_4698.ps1`
6. `get_event_4624_4672_4648_privileged.ps1`
7. `get_event_5136_gpo.ps1`
8. `get_wmi_subscriptions.ps1`

Privileged groups first to establish which accounts matter.

Then each current-state script immediately followed by its matching event-history script, so the comparison (current vs. historical, including anything deleted) is easy while both are fresh: services → 7045, then scheduled tasks → 4698.

Privileged logon activity comes next, since it depends on the account list from step 1 and shows how those accounts have actually been used.

GPO changes follow, since a privileged account from step 1/6 is the most likely one to have made a legitimate or malicious GPO change.

WMI subscriptions run last — the stealthiest and least common persistence mechanism, and the one requiring the most manual review (no timestamp, no built-in "current state" cmdlet).

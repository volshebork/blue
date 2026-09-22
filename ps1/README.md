# Recommended Run Order

1. `get_privileged_groups.ps1`
2. `get_current_services.ps1`
3. `get_event_7045.ps1`
4. `get_current_scheduledtask_creation_dates.ps1`
5. `get_event_4698.ps1`

Privileged groups first to establish which accounts matter...

then each current-state script...

immediately followed by its matching event-history script...

so the comparison (current vs. historical, including anything deleted) is easy while both are fresh.

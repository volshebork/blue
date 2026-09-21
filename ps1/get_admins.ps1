# Ensure the Active Directory module is loaded
Import-Module ActiveDirectory

# Define the group name
$GroupName = "Domain Admins"

# Fetch group members, filter for user accounts only, and grab their creation dates
$DomainAdminsReport = Get-ADGroupMember -Identity $GroupName -Recursive | 
    Where-Object { $_.objectClass -eq "user" } | 
    ForEach-Object {
        Get-ADUser -Identity $_.SamAccountName -Properties whenCreated
    } | 
    Select-Object Name, SamAccountName, @{Name="CreationDate"; Expression={$_.whenCreated}}, Enabled

# Option 1: Display the results in an interactive GUI grid
$DomainAdminsReport | Out-GridView -Title "Domain Admins Creation Dates"

# Option 2: Uncomment the line below to export the results directly to a CSV file
# $DomainAdminsReport | Export-Csv -Path "C:\temp\DomainAdmins_CreationDates.csv" -NoTypeInformation

# accept two parameters: password and username
Param(
   [Parameter(Position=1)]
   [string]$tmppass,

   [Parameter(Position=2)]
   [string]$user

)

# create a credential object from the username and password
$password = ConvertTo-SecureString "$tmppass" -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential ("labs\$user", $password)

# create OUs
New-ADOrganizationalUnit -Server labs.local -Name "UserAccounts" -Credential $cred
New-ADOrganizationalUnit -Server labs.local -Name "ComputerAccounts" -Credential $cred
New-ADOrganizationalUnit -Server labs.local -Name "AdminAccounts" -Credential $cred

# create groups
redircmp "OU=ComputerAccounts,DC=labs,DC=local"

# initiate a new array
$users = @()

# read users.csv columns into variables
Import-Csv .\users.csv | ForEach-Object {
    # create an array of the user's info from each row
    $user = @($_.UserPrincipalName, $_.Path, $_.Server, $_.GivenName, $_.Surname, $_.Enabled, $_.Name, $_.desc, $_.office, $_.title, $_.company, $_.AccountPassword)

    # add the user's info to the users array
    $users += $user
}

# loop through users array and create users
foreach ($user in $users) {
    # dry-run: print the user's info
    $user

    # TODO: indexes are off
    # create the user
    # New-ADUser -Name $user[6] -GivenName $user[3] -Surname $user[4] -UserPrincipalName $user[0] -Path $user[1] -Server $user[2] -Enabled $user[5] -Description $user[7] -Office $user[8] -Title $user[9] -Company $user[10] -AccountPassword $user[11] -Credential $cred
}

# TODO: QA
# add user to domain admins group
Add-ADGroupMember -Identity "Domain Admins" -Members Sylvia.Sutton -Server labs.local -Credential $cred

# TODO: probably need to move to another for loop
# move users and computers to appropriate OUs
Move-ADObject -Identity "CN=$user,CN=Users,DC=labs,DC=local" -TargetPath "OU=AdminAccounts,DC=labs,DC=local" -Server labs.local -Credential $cred
Move-ADObject -Identity "CN=ws01,CN=Computers,DC=labs,DC=local" -TargetPath "OU=ComputerAccounts,DC=labs,DC=local" -Server labs.local -Credential $cred

# TODO: ^^
# set user's script path
Set-ADUser $user -ScriptPath \\dc01.labs.local\labs\scripts\mapdrive.bat -Server labs.local -Credential $cred

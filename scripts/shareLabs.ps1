New-SMBShare -Name "labs" -Path "C:\labs" -FullAccess "labs.local\Domain Users"
$acl = Get-Acl -Path C:\labs
#List Users/Groups in ACL with permissions
$acl.Access | Select IdentityReference, FileSystemRights
#Add ACE to grant Group ReadAndExecute for "This Folder, Subfolders and Files"
$rule = New-Object System.Security.AccessControl.FileSystemAccessRule("Everyone","ReadAndExecute", "ContainerInherit, ObjectInherit", "None", "Allow")
$acl.AddAccessRule($rule)
#Set the modified ACL
Set-Acl -Path C:\labs -AclObject $aclNew-SMBShare -Name "labs" -Path "C:\labs" -FullAccess "labs.local\Domain Users"

# Powershell script to add users to desired groups for WLAN access
#
# Author: Charles Holbrook
#
#
# Version 1.0 - 02/12/2021
# Version 1.1 - 02/12/2021 (Updated to find domain name instead of having to manually edit and add it.)
# Version 1.2 - 02/14/2021 (Updated to check if AD groups exist and alert if they do not.)
#
# You should only need to modify lines 15 and 16 to match group names
# 


# Change to match district name for WLAN groups (Note: Must match cn of group which in most cases will be the name you see in ADUC)
$StaffWLAN = "Staff-BYOD"
$StuWLAN = "Student-BYOD"

# Change to match OU names for OUs containing accounts
# These shouldn't need changed as they are universal through out KETS
$Leadership = "Leadership"
$Staff = "Staff"
$Students = "Students"


# <---------- STOP - Modify only if needed from this point on as you can break something ---------->

# Lets verifiy that Staff and Student WLAN groups exist first, if not alert
$StaffWLANExist = Get-ADGroup -LDAPFilter "(SAMAccountName=$StaffWLAN)"
$StuWLANExist = Get-ADGroup -LDAPFilter "(SAMAccountName=$StuWLAN)"

# Check if Staff WLAN Exist
If($StaffWLANExist -ne $null) {

# Check if Student WLAN
If ($StuWLANExist -ne $null) {

# Get Domain Name
$District = (Get-ADDomain).name

# Find which Domain Controller we are connected and running against since replication can take time
$LS = $env:LOGONSERVER

# Build Domain name in LDAP format
$Domain = (Get-ADDomain).distinguishedName

# Build Leadership and Staff OU Path
$StaffOU = "OU=" + $Staff + "," + $Domain
$LeadershipOU = "OU=" + $Leadership + "," + $Domain
$StuOU = "OU=" + $Students + "," + $Domain

# Build DN for each group, this is easier than having to go find DN via attribute editor
$StaffWLANGroupDN = (Get-ADGroup -Identity $StaffWLAN).DistinguishedName
$StudentWLANGroupDN = (Get-ADGroup -Identity $StuWLAN).DistinguishedName


# Search OUs for users not a member of group (Note: We will only look for accounts with an email address as some generic accounts used by districts are not mail enabled)
CLS

Write-Host "Reading Users from $Leadership OU (Please note this may take some time depending on number of objects.)"
$LeadershipMembers = Get-ADUser -SearchBase $LeadershipOU -Filter * -Properties * | where-object {$_.MemberOf -notcontains $StaffWLANGroupDN} | Where-Object {$_.mail -ne $null}
Write-Host "Found" $LeadershipMembers.Count "user accounts."
Write-Host

Write-Host "Reading Users from $Staff OU (Please note this may take some time depending on number of objects.)"
$StaffMembers = Get-ADUser -SearchBase $StaffOU -Filter * -Properties * | where-object {$_.MemberOf -notcontains $StaffWLANGroupDN} | Where-Object {$_.mail -ne $null}
Write-Host "Found" $StaffMembers.Count "user accounts."
Write-Host

Write-Host "Reading Users From $Students OU (Please note this may take some time depending on number of objects.)"
$StudentMembers = Get-ADUser -SearchBase $StuOU -Filter * -Properties * | where-object {$_.MemberOf -notcontains $StudentWLANGroupDN} | Where-Object {$_.mail -ne $null}
Write-Host "Found" $StudentMembers.count "user accounts."
Write-Host
Sleep 2

# Return Logon Server Information and give time to stop script if needed.
CLS
Write-Host "We are currently connected to $LS, once script completes please give a few minutes for replication to occur between local Domain Controllers."
Write-Host ""
Write-Host "Script will continue in 5 seconds! --> If you need to stop script press CTRL + C <--"
Sleep 5
CLS 

# <--------------------------->
# Begin adding users to groups

CLS

IF ($LeadershipMembers.count -gt 0){
    Write-Host "Processing Leadership OU"
    Sleep 2

    # Add to Leadership Group
    ForEach ($LeadershipMember in $LeadershipMembers) {
        Write-Host "Adding (" $LeadershipMember.displayname ") to" $StaffWLAN
        #add-adgroupmember -identity $StaffWLAN -Members $LeadershipMember.SamAccountName
    }
} Else {
    Write-Host "No accounts found in Leadership OU to add to $StaffWLAN"
    Write-Host "Possible causes include users are already a member or OU contains no accounts"
}

Sleep 4

If ($StaffMembers.Count -gt 0){
    Write-Host "Processing Staff OU"
    Sleep 2

# Add to Staff Group
    ForEach ($StaffMember in $StaffMembers) {
        Write-Host "Adding (" $StaffMember.displayname ") to" $StaffWLAN
        add-adgroupmember -identity $StaffWLAN -Members $StaffMember.SamAccountName
    }
} Else {
    Write-Host "No accounts found in Staff OU to add to $StaffWLAN"
    Write-Host "Possible causes include users are already a member or OU contains no accounts"
}

Sleep 4

If ($StudentMembers.Count -gt 0){
    Write-Host "Processing Student OU"
    Sleep 2

    # Add to Student Group
    ForEach ($StudentMember in $StudentMembers) {
        Write-Host "Adding (" $StudentMember.displayname ") to" $StuWLAN
        add-adgroupmember -identity $StuWLAN -Members $StudentMember.SamAccountName
    }
} Else {
    Write-Host "No accounts found in Student OU to add to $StuWLAN"
    Write-Host "Possible causes include users are already a member or OU contains no accounts"
}

Sleep 3

Write-Host "Finished processing all Accounts in the following OUs $Leadership, $Staff, $Students"
Sleep 2
Write-Host "You may now close the script."

} Else {
    
    Write-Host "$StuWLAN group not found, please check spelling or verifiy if group exist in AD."
    }
} Else {
    Write-Host "$StaffWLAN group no found, please check spelling or verify if group exist in AD."
    }
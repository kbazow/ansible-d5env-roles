$sshDir = "$env:USERPROFILE\.ssh"

$metron_username = Read-Host -Prompt "Enter your Metron userid"

$metron_password0 = "passwd0"
$metron_password1 = "passwd1"
$first_try = $true

while ($metron_password0 -cne $metron_password1)
{
    if ($first_try)
    {
        $first_try = $false
    }
    else
    {
        Write-Host "Passwords did not match." -ForegroundColor red
    }
    $securedValue = Read-Host -Prompt "Enter your Metron password" -AsSecureString
    $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($securedValue)
    $metron_password0 = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)

    $securedValue = Read-Host -Prompt "Renter your Metron password" -AsSecureString
    $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($securedValue)
    $metron_password1 = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
}

$encryptSecretsPassword0 = "passwd0"
$encryptSecretsPassword1 = "passwd1"
$first_try = $true

while ($encryptSecretsPassword0 -cne $encryptSecretsPassword1)
{
    if ($first_try)
    {
        $first_try = $false
    }
    else
    {
        Write-Host "Passwords did not match." -ForegroundColor red
    }

    $encryptSecretsPasswordSecured = Read-Host -Prompt "Enter the secrets password" -AsSecureString
    $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($encryptSecretsPasswordSecured)
    $encryptSecretsPassword0 = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)

    $encryptSecretsPasswordSecured = Read-Host -Prompt "Renter the secrets password" -AsSecureString
    $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($encryptSecretsPasswordSecured)
    $encryptSecretsPassword1 = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
}

$git_private_ssh_key_file = Read-Host -Prompt "Enter path to git private ssh key file [Enter to skip]"
$git_public_ssh_key = ""
$git_private_ssh_key = ""
if ($git_private_ssh_key_file -match "\w")
{
    $git_public_ssh_key = [System.IO.File]::ReadAllLines($git_private_ssh_key_file + ".pub")
    foreach ($line in [System.IO.File]::ReadLines($git_private_ssh_key_file))
    {
        $git_private_ssh_key += " $line`n"
    }
}

New-Item -Path . -Name ".\secrets.yml" -ItemType "file" -Force
Add-Content -Path .\secrets.yml  -Value "metsci_username: $metron_username"
Add-Content -Path .\secrets.yml  -Value "metsci_password: $metron_password0"

Add-Content -Path .\secrets.yml  -Value "git_public_ssh_key: $git_public_ssh_key"
Add-Content -Path .\secrets.yml  -Value "git_private_ssh_key: |
$git_private_ssh_key"

New-Item -Path $sshDir -Name "secrets_pwd.txt" -ItemType "file" -Force
Add-Content -Path $sshDir\secrets_pwd.txt -Value $encryptSecretsPassword0

Get-EncryptedAnsibleVault -Path .\secrets.yml -Password $encryptSecretsPasswordSecured | Set-Content -Path .\secrets.yml -NoNewLine

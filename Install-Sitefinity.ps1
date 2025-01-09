# Configure developer's machine and install dependencies to use Sitefinity CMS.

# Not checked if works on built-in PowerShell 5, so requires modern PowerShell Core 7 or later
if ((Get-Host).Version.Major -lt 7) { Write-Output "This script requires PowerShell 7 or newer. Download and install it from https://github.com/PowerShell/PowerShell/releases or use winget: winget.exe install PowerShell --accept-package-agreements --accept-source-agreements --source winget"; exit }

$isElevated = (New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isElevated) {
    write-host "This script will start an elevated instance to perform its work, expect an UAC prompt."
    Write-Host "Press any key to continue:"
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    
    $newProcess = New-Object System.Diagnostics.ProcessStartInfo $([System.Environment]::ProcessPath);
    $newProcess.Arguments = $myInvocation.MyCommand.Definition;
    $newProcess.Verb = "RunAs";
    $newProcess.UseShellExecute = $true;
    [System.Diagnostics.Process]::Start($newProcess);
    exit
}

# Enable required Windows features
Write-Output "Configure required Windows Optional Features"
Enable-WindowsOptionalFeature -FeatureName IIS-ASPNET45 -Online -All -NoRestart

#Install .NET 9
Write-Output "Installing .NET 9."
&winget.exe install Microsoft.DotNet.SDK.9 --accept-package-agreements --accept-source-agreements --source winget

#Install NodeJS
Write-Output "Installing Node.js."
&winget.exe install OpenJS.NodeJS.LTS --accept-package-agreements --accept-source-agreements --source winget

# Install Visual Studio
Write-Output "Installing Visual Studio 2022."
Start-Process "$PSScriptRoot\VisualStudioSetup2022.exe" "-p --norestart --add Microsoft.VisualStudio.Workload.NetWeb --add Microsoft.Net.ComponentGroup.4.8.DeveloperTools --add Microsoft.Net.Component.4.8.TargetingPack --add Microsoft.VisualStudio.Component.AspNet" -Wait

#Install SQL Server
Write-Output "Installing SQL Server Express 2022."
Start-Process "$PSScriptRoot\SQL2022-SSEI-Expr.exe" "/IAcceptSqlServerLicenseTerms /Action=Install /Quiet" -Wait

# Install various tools
Write-Output "Installing useful development tools."
&winget install git.git --silent --accept-package-agreements --accept-source-agreements --source winget
&winget install Microsoft.VisualStudioCode --silent --accept-package-agreements --accept-source-agreements --source winget

# Refresh the PATH so that newly installed tools can be run
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

# Add Sitefinity NuGet source
Write-Output "Add Sitefinity NuGet source"
&dotnet.exe nuget add source https://nuget.sitefinity.com/nuget -n Sitefinity

# Ask for restart
$ans = $Host.UI.PromptForChoice('You need to restart your machine for the configuration changes to take effect.', 'Restart now?', @('&Yes', '&No'), 1)
if ($ans -eq 0) { 
    &shutdown -r -t 0 
}


﻿$env:INSTALL_LATEST_ONLY=$true
function Install-Nodejs {

    $avvmRoot = "$env:SYSTEMDRIVE\avvm\node"

    $nodeVersions = @(
        "12.22.12",
        "13.14.0",
        "14.21.1",
        "15.14.0",
        "16.20.1",
        "17.9.1",
        "18.20.3",
        "19.9.0",
        "20.17.0",
        "21.7.3",
        "22.11.0",
        "23.2.0"
    )

    # if (-not $env:INSTALL_LATEST_ONLY) {
    #     $nodeVersions = @(

    #     ) + $nodeVersions
    # }

    $nodePlatforms = @(
        "x86",
        "x64"
    )

    $fileTemplates = @{
        "nodejs_x64" = @{
            "files_ps1"     = '$files = @{ "nodejs" = "$env:ProgramFiles\nodejs" }'
            "install_ps1"   = 'reg import "$PSScriptRoot\install.reg" 2> $null'
            "uninstall_ps1" = 'Remove-Item -Path ''HKCU:\Software\Node.js'' -Recurse -Force'
            "install_reg"   = 'Windows Registry Editor Version 5.00

[HKEY_CURRENT_USER\Software\Node.js]
"InstallPath"="C:\\Program Files\\nodejs\\"
"Version"="{version}"

[HKEY_CURRENT_USER\Software\Node.js\Components]
"DocumentationShortcuts"=dword:00000001
"EnvironmentPathNpmModules"=dword:00000001'
        }
        "nodejs_x86" = @{
            "files_ps1"     = '$files = @{ "nodejs" = "${env:ProgramFiles(x86)}\nodejs" }'
            "install_ps1"   = 'reg import "$PSScriptRoot\install.reg" 2> $null'
            "uninstall_ps1" = 'Remove-Item -Path ''HKCU:\Software\Node.js'' -Recurse -Force'
            "install_reg"   = 'Windows Registry Editor Version 5.00

[HKEY_CURRENT_USER\Software\Node.js]
"InstallPath"="C:\\Program Files (x86)\\nodejs\\"
"Version"="{version}"

[HKEY_CURRENT_USER\Software\Node.js\Components]
"DocumentationShortcuts"=dword:00000001
"EnvironmentPathNpmModules"=dword:00000001'
        }
        "iojs_x64"   = @{
            "files_ps1"     = '$files = @{ "iojs" = "$env:ProgramFiles\iojs" }'
            "install_ps1"   = 'reg import "$PSScriptRoot\install.reg" 2> $null'
            "uninstall_ps1" = 'Remove-Item -Path ''HKCU:\Software\io.js'' -Recurse -Force'
            "install_reg"   = 'Windows Registry Editor Version 5.00

[HKEY_CURRENT_USER\Software\io.js]
"InstallPath"="C:\\Program Files\\iojs\\"
"Version"="{version}"

[HKEY_CURRENT_USER\Software\io.js\Components]
"DocumentationShortcuts"=dword:00000001
"EnvironmentPathNpmModules"=dword:00000001'
        }
        "iojs_x86"   = @{
            "files_ps1"     = '$files = @{ "iojs" = "${env:ProgramFiles(x86)}\iojs" }'
            "install_ps1"   = 'reg import "$PSScriptRoot\install.reg" 2> $null'
            "uninstall_ps1" = 'Remove-Item -Path ''HKCU:\Software\io.js'' -Recurse -Force'
            "install_reg"   = 'Windows Registry Editor Version 5.00

[HKEY_CURRENT_USER\Software\io.js]
"InstallPath"="C:\\Program Files (x86)\\iojs\\"
"Version"="{version}"

[HKEY_CURRENT_USER\Software\io.js\Components]
"DocumentationShortcuts"=dword:00000001
"EnvironmentPathNpmModules"=dword:00000001'
        }
    }

    function Get-Version([string]$str) {
        $versionDigits = $str.Split('.')
        $version = @{
            major    = -1
            minor    = -1
            build    = -1
            revision = -1
            number   = 0
        }

        if ($versionDigits.Length -gt 0) {
            $version.major = [int]$versionDigits[0]
        }
        if ($versionDigits.Length -gt 1) {
            $version.minor = [int]$versionDigits[1]
        }
        if ($versionDigits.Length -gt 2) {
            $version.build = [int]$versionDigits[2]
        }
        if ($versionDigits.Length -gt 3) {
            $version.revision = [int]$versionDigits[3]
        }

        for ($i = 0; $i -lt $versionDigits.Length; $i++) {
            $version.number += [long]$versionDigits[$i] -shl 16 * (3 - $i)
        }

        return $version
    }

    function ProductName($version) {
        $v = Get-Version $version
        if ($v.Major -eq 0 -or $v.Major -ge 4) {
            return 'Node.js'
        }
        else {
            return 'io.js'
        }
    }

    function ProductInstallDirectory($version, $platform) {
        $v = Get-Version $version
        if (($v.Major -eq 0 -or $v.Major -ge 4) -and $platform -eq 'x86') {
            return "${env:ProgramFiles(x86)}\nodejs"
        }
        elseif ($v.Major -ge 1 -and $platform -eq 'x86') {
            return "${env:ProgramFiles(x86)}\iojs"
        }
        elseif ($v.Major -eq 0 -or $v.Major -ge 4) {
            return "$env:ProgramFiles\nodejs"
        }
        elseif ($v.Major -ge 1) {
            return "$env:ProgramFiles\iojs"
        }
    }

    function Get-NodeJsInstallPackage {
        param
        (
            [Parameter(Mandatory = $true)]
            [string]$version,

            [Parameter(Mandatory = $false)]
            [string]$bitness = 'x86'
        )

        $v = Get-Version $version
    
        if ($v.Major -ge 4 -and $bitness -eq 'x86') {
            $packageUrl = "http://nodejs.org/dist/v$version/node-v$version-x86.msi"
        }
        elseif ($v.Major -ge 4 -and $bitness -eq 'x64') {
            $packageUrl = "http://nodejs.org/dist/v$version/node-v$version-x64.msi"
        }
        elseif ($v.Major -eq 0 -and $v.Minor -gt 6 -and $bitness -eq 'x86') {
            $packageUrl = "http://nodejs.org/dist/v$version/node-v$version-x86.msi"
        }
        elseif ($v.Major -eq 0 -and $v.Minor -le 6 -and $bitness -eq 'x86') {
            $packageUrl = "http://nodejs.org/dist/v$version/node.msi"
        }
        elseif ($v.Major -ge 1 -and $bitness -eq 'x86') {
            $packageUrl = "https://iojs.org/dist/v$version/iojs-v$version-x86.msi"
        }
        elseif ($v.Major -eq 0 -and $v.Minor -gt 6) {
            $packageUrl = "http://nodejs.org/dist/v$version/x64/node-v$version-x64.msi"
        }
        elseif ($v.Major -eq 0 -and $v.Minor -le 6) {
            $packageUrl = "http://nodejs.org/dist/v$version/x64/node.msi"
        }
        elseif ($v.Major -ge 1) {
            $packageUrl = "https://iojs.org/dist/v$version/iojs-v$version-x64.msi"
        }

        Write-Host "Downloading package from $packageUrl"
    
        $packageFileName = Join-Path ([IO.Path]::GetTempPath()) $packageUrl.Substring($packageUrl.LastIndexOf('/') + 1)
        (New-Object Net.WebClient).DownloadFile($packageUrl, $packageFileName)
        return $packageFileName
    }

    function Start-NodeJsInstallation {
        param
        (
            [Parameter(Mandatory = $true)]
            [string]$version,

            [Parameter(Mandatory = $false)]
            [string]$bitness = 'x86'
        )

        $v = Get-Version $version

        Write-Host "Installing $(ProductName($version)) v$version ($bitness)..."
        $packageFileName = Get-NodeJsInstallPackage $version $bitness
        cmd /c start /wait msiexec /i "$packageFileName" /q
        del $packageFileName
    }

    function GetUninstallString($productName) {
        $x64items = @(Get-ChildItem "HKLM:SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall")
        $uninstallString = ($x64items + @(Get-ChildItem "HKLM:SOFTWARE\wow6432node\Microsoft\Windows\CurrentVersion\Uninstall") `
            | ForEach-object { Get-ItemProperty Microsoft.PowerShell.Core\Registry::$_ } `
            | Where-Object { $_.DisplayName -and $_.DisplayName -eq $productName } `
            | Select UninstallString).UninstallString

        if ($uninstallString) {
            return $uninstallString.replace('MsiExec.exe /I{', '/x{').replace('MsiExec.exe /X{', '/x{')
        }
        else {
            return $uninstallString
        }
    }

    for ($i = 0; $i -lt $nodeVersions.Length; $i++) {
        for ($j = 0; $j -lt $nodePlatforms.Length; $j++) {
            $v = Get-Version $nodeVersions[$i]
            $nodeVersion = $nodeVersions[$i]
            $nodePlatform = $nodePlatforms[$j]
            $nodeName = ProductName $nodeVersion

            # is it the last install?
            $lastOne = ($i -eq ($nodeVersions.Length - 1) -and $j -eq ($nodePlatforms.Length - 1))

            Write-Host "Installing $nodeName $nodeVersion $nodePlatform..." -ForegroundColor Cyan

            $avvmDir = "$avvmRoot\$nodeVersion\$nodePlatform"
            $installDir = ProductInstallDirectory $nodeVersion $nodePlatform
            $dirName = [IO.Path]::GetFileName($installDir)

            if (Test-Path "$avvmDir\$dirName") {
                Write-Host "$nodeName $nodeVersion $nodePlatform already installed" -ForegroundColor Gray
                continue
            }

            # create avvm dir
            Write-Host "Creating directory $avvmDir..."
            New-Item $avvmDir -ItemType Directory -Force | Out-Null

            # uninstall current node.js or io.js
            $uninstallCommand = (GetUninstallString $nodeName)
            if ($uninstallCommand) {
                Write-Host "Uninstalling $nodeName..."
                cmd /c start /wait msiexec.exe $uninstallCommand /quiet   
            }

            # download required package
            if ($v.major -ge 23 -and $nodePlatform -eq 'x86') {
                continue
            }
            else {
                Start-NodeJsInstallation $nodeVersion $nodePlatform
            }

            if (-not $lastOne) {
                # copy
                Write-Host "Copying $installDir to $avvmDir\$dirName..."
                Copy-Item $installDir -Destination "$avvmDir\$dirName" -Recurse
            }
            else {
                # mark last version as active
                $registryKey = "HKLM:\SOFTWARE\Appveyor\VersionManager\node"
                New-Item $registryKey -Force | Out-Null
                Set-ItemProperty -Path $registryKey -Name "Version" -Value $nodeVersion
                Set-ItemProperty -Path $registryKey -Name "Platform" -Value $nodePlatform
            }

            # adding helper files
            [IO.File]::WriteAllText("$avvmDir\files.ps1", $fileTemplates["$($dirName)_$($nodePlatform)"]["files_ps1"])
            [IO.File]::WriteAllText("$avvmDir\install.ps1", $fileTemplates["$($dirName)_$($nodePlatform)"]["install_ps1"])
            [IO.File]::WriteAllText("$avvmDir\uninstall.ps1", $fileTemplates["$($dirName)_$($nodePlatform)"]["uninstall_ps1"])
            [IO.File]::WriteAllText("$avvmDir\install.reg", $fileTemplates["$($dirName)_$($nodePlatform)"]["install_reg"].replace('{version}', $nodeVersion))

            # fix node.exe alias for io.js
            $avvmIoJsPath = Join-Path $avvmDir "iojs"

            if (Test-Path $avvmIoJsPath) {
                    
                Remove-Item "$avvmIoJsPath\node.exe" -Force

                '@IF EXIST "%~dp0\iojs.exe" ( 
    "%~dp0\iojs.exe" %* 
) ELSE ( 
    iojs %* 
)' | Out-File "$avvmIoJsPath\node.cmd" -Encoding ascii
            }

            Write-Host "$nodeName $nodeVersion $nodePlatform installed" -ForegroundColor Green
        }
    }
}

Install-Nodejs

Add-Path "${env:ProgramFiles(x86)}\nodejs"
Add-Path "$env:ProgramFiles\nodejs"
Add-Path "${env:ProgramFiles(x86)}\iojs"
Add-Path "$env:ProgramFiles\iojs"
Add-Path "$env:APPDATA\npm"

# set AVVM URL
[System.Environment]::SetEnvironmentVariable("AVVM_DOWNLOAD_URL", "https://appveyordownloads.blob.core.windows.net/avvm", "Machine")
$env:INSTALL_LATEST_ONLY=$null
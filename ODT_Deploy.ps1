# Office Deployment Tool URL
$odtUrl = "https://download.microsoft.com/download/6c1eeb25-cf8b-41d9-8d0d-cc1dbc032140/officedeploymenttool_19628-20192.exe"

# Creates directory
$outputDir    = "$env:LOCALAPPDATA\OfficeDeploymentTool"
$odtInstaller = "$outputDir\ODTInstaller.exe"
$configFile   = "$outputDir\Office.xml"
New-Item -ItemType Directory -Path $outputDir -ErrorAction SilentlyContinue | Out-Null

# Creates configuration for Office
New-Item -Path "$outputDir" -Name "Office.xml" -ItemType "File" -Value 'Office Configuration Here' -Force | Out-Null

# Download Office Deployment Tool from Microsoft
Invoke-WebRequest -Uri $odtUrl -OutFile $odtInstaller

# Silently extract the Office Deployment Tool
Start-Process -FilePath $odtInstaller -ArgumentList "/quiet /extract:$outputDir" -Wait

# Run setup to download, apply the configuration, and install Office
Start-Process -Verb runAs -FilePath "$outputDir\setup.exe" -ArgumentList "/download `"$configFile`"" -Wait
Start-Process -Verb runAs -FilePath "$outputDir\setup.exe" -ArgumentList "/configure `"$configFile`"" -Wait

# Cleanup with retry
$timeout  = (Get-Date).AddMinutes(3)
$attempts = 0

while ($attempts -lt 3) {
    if (((Get-Date) -lt $timeout) -and (Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.Path -like "$outputDir\*" })) {
        Start-Sleep -Seconds 5
        continue
    }

    $attempts++
    try {
        Remove-Item -Path $outputDir -Recurse -Force -ErrorAction Stop
        break
    }
    catch {
        Start-Sleep -Seconds 15
    }
}

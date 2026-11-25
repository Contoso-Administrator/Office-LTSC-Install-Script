# Office LTSC Install Script (Office Deployment Tool)

This lightweight PowerShell script is built for unattended deployment through any RMM/endpoint management platforms that don't already have a pre-configured option. It does this by downloading the Microsoft **Office Deployment Tool (ODT)**, extracts it, downloads and installs Click-to-Run Office products from an inline XML configuration, and then deletes the installation folder. This is an easily managed solution as the configuration file is written directly into the script, along with the install of the Office Deployment Tool and application(s).  

> [!CAUTION]
> For large deployments, it is best practice to [self host both the Office Deployment Tool](https://github.com/Contoso-Administrator/Office-LTSC-Install-Script#updating-the-office-deployment-tool-url) and <a href="https://learn.microsoft.com/en-us/microsoft-365-apps/deploy/office-deployment-tool-configuration-options#downloadpath-attribute-part-of-add-element" target="_blank">Click-to-Run installation files</a> as the Microsoft CDN has rate-limiting in place for both. 
<br />

## Workflow

```mermaid
flowchart LR
    A[Creates the install directory] --> B[Writes the XML config]
	    B --> C[Download/Extracts ODT] --> D[ODT installs app] --> E[Deletes install directory]
```

The script first creates the installation directory (`$env:LOCALAPPDATA\OfficeDeploymentTool`) to then download the Office Deployment Tool to it. Once the download is complete, ODT is then run against the XML config to install the desired application(s).

After installation, the script then deletes the installation folder within a single loop that waits up to 3 minutes for any child processes to end and makes 3 attempts to delete the folder (to handle short file locks such as antivirus scans). If every attempt fails, the installation folder stays in place and the script exits without an error.
<br />

## Updating the Configuration XML

The Office configuration is written inline in <a href="https://github.com/Contoso-Administrator/Office-LTSC-Install-Script/blob/1d4b2f3812792a50b9a8e7f60a39e9d00d55479c/ODT_Deploy.ps1#L11" target="_blank">line 11</a>. Replace the text `Office Configuration Here` with the contents of your Click-to-Run XML configuration, inside the **single quotes**. This creates the XML configuration file instead of needing to transfer it:
```powershell
New-Item -Path "$outputDir" -Name "Office.xml" -ItemType "File" -Value 'Office Configuration Here' -Force | Out-Null
```
<br />

Example configuration of a Office LTSC Standard 2024 Click-to-Run deployment:
```powershell
New-Item -Path "$outputDir" -Name "Office.xml" -ItemType "File" -Value '<Configuration>
  <Add OfficeClientEdition="64" Channel="PerpetualVL2024">
    <Product ID="Standard2024Volume" PIDKEY="XXXXX-XXXXX-XXXXX-XXXXX-XXXXX">
      <Language ID="en-us" />
      <ExcludeApp ID="Groove" />
      <ExcludeApp ID="Lync" />
    </Product>
  </Add>
  <Property Name="AUTOACTIVATE" Value="1" />
  <Updates Enabled="FALSE" />
  <Display Level="None" AcceptEULA="TRUE" />
  <Remove All="TRUE" />
</Configuration>' -Force | Out-Null
```
<br />

>[!Note]
> For the script to be a silent install, the following must be included in the configuration
> file:  `<Display Level="None" AcceptEULA="TRUE" />`
>
<br />

This script can be configured to install either the suite of Office applications or as just a standalone (Project, Visio) installer. Reviewing <a href="https://learn.microsoft.com/en-us/microsoft-365-apps/deploy/office-deployment-tool-configuration-options" target="_blank">the configuration options</a> that are available is recommended, as there are many options on how to update, exclude, download, and target these applications for deployment.
<br />

> [!TIP]
> Use the [Office Customization Tool](https://config.office.com/deploymentsettings) to build a configuration file for all Microsoft Click-to-Run applications in the web interface, then paste the exported XML into the script.
<br />

## Updating the Office Deployment Tool URL

Microsoft releases new builds for the Office Deployment Tool regularly and recommends always using the latest version. Each release has a different download URL, so you need to update the variable `$odtUrl` when a new version comes out.

>[!Note]
>If the Office Deployment Tool is locally hosted, you will need to replace <a href="https://github.com/Contoso-Administrator/Office-LTSC-Install-Script/blob/1d4b2f3812792a50b9a8e7f60a39e9d00d55479c/ODT_Deploy.ps1#L14" target="_blank">line 14</a> with the file transfer and use the variable `$odtInstaller` for the destination:
>```powershell
>Copy-Item -Path "\\Remote\Folder\officedeploymenttool_20527-20150.exe" -Destination $odtInstaller
>```
<br />

#### Step 1: Find the latest download link

1. Navigate to the [official download page](https://www.microsoft.com/en-us/download/details.aspx?id=49117)
2. Right click the **Download** option to select 'Copy link address':
<img width="1636" height="642" alt="ODT" src="https://github.com/user-attachments/assets/0a0969e9-2cbc-451b-b490-3076405bf644" />
<br />

The link should look like this:
```
https://download.microsoft.com/download/<GUID>/officedeploymenttool_<build>.exe
```
<br />

#### Step 2: Verify the link

Before deploying, check that the URL works by pasting it into a browser and confirming that it downloads the ODT executable.

> [!NOTE]
> Microsoft removes old ODT download links over time. If the script fails at the download step with a `404` error, the URL is out of date and needs to be updated.
<br />

#### Step 3: Update the script

Replace the value of `$odtUrl` in <a href="https://github.com/Contoso-Administrator/Office-LTSC-Install-Script/blob/1d4b2f3812792a50b9a8e7f60a39e9d00d55479c/ODT_Deploy.ps1#L2" target="_blank">line 2</a> of the script with the updated URL:
```powershell
$odtUrl = "https://download.microsoft.com/download/<new-GUID>/officedeploymenttool_<new-build>.exe"
```
<br />

## Usage

To manually start the script, run the following command from an elevated PowerShell session:
```powershell
& "C:\Path\to\folder\ODT_Deploy.ps1"
```
<br />

#### RMM
Run the task as **SYSTEM** or as an account with local admin rights. When the script runs as **SYSTEM**, the installation folder `$env:LOCALAPPDATA` resolves to:
  ```
  C:\Windows\System32\config\systemprofile\AppData\Local
  ```

>[!NOTE]
>ODT and Office install logs are written to `%TEMP%` (or `C:\Windows\Temp` when running as SYSTEM).
<br />

## Requirements
>- Windows 10/11
>- PowerShell 5.1 or later
>- Script must be ran with **Administrator rights**
>- Internet access to `download.microsoft.com` and the Office CDN
>- A valid Office license or volume activation method for the product you're installing

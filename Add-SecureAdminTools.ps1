#Install WinGet
#Based on this gist: https://gist.github.com/crutkas/6c2096eae387e544bd05cde246f23901
$hasPackageManager = Get-AppPackage -name 'Microsoft.DesktopAppInstaller'
if (!$hasPackageManager -or [version]$hasPackageManager.Version -lt [version]"1.10.0.0") {
	"Installing Microsoft.UI.Xaml"
	$downloadUrl = 'https://globalcdn.nuget.org/packages/microsoft.ui.xaml.2.7.3.nupkg'
	###Invoke-WebRequest -method "Head" $downloadUrl | Select Headers -ExpandProperty Headers
	Invoke-WebRequest $downloadUrl -OutFile $env:LOCALAPPDATA\temp\Microsoft.UI.Xaml.zip
	#Unzip archive
	Expand-Archive $env:LOCALAPPDATA\temp\Microsoft.UI.Xaml.zip

	Add-AppxPackage -Path $env:LOCALAPPDATA\temp\Microsoft.UI.Xaml\tools\AppX\x64\Release\Microsoft.UI.Xaml.2.7.appx

    "Installing winget Dependencies"
    Add-AppxPackage -Path 'https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx'

    $releases_url = 'https://api.github.com/repos/microsoft/winget-cli/releases/latest'

    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $releases = Invoke-RestMethod -uri $releases_url
    $latestRelease = $releases.assets | Where { $_.browser_download_url.EndsWith('msixbundle') } | Select -First 1

    "Installing winget from $($latestRelease.browser_download_url)"
    Add-AppxPackage -Path $latestRelease.browser_download_url
}
else {
    "winget already installed"
}

#Configure WinGet
Write-Output "Configuring winget"

#winget config path from: https://github.com/microsoft/winget-cli/blob/master/doc/Settings.md#file-location
$settingsPath = "$env:LOCALAPPDATA\Packages\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe\LocalState\settings.json";
$settingsJson = 
@"
    {
        // For documentation on these settings, see: https://aka.ms/winget-settings
        "experimentalFeatures": {
          "experimentalMSStore": true,
        }
    }
"@;
$settingsJson | Out-File $settingsPath -Encoding utf8

#Install New apps
Write-Output "Installing Apps"
$apps = @(
    @{name = "Microsoft.AzureCLI" }, 
    @{name = "7zip.7zip" }
    @{name = "9NP355QT2SQB"; source = "msstore" }, ##Azure VPN
    @{name = "Microsoft.WindowsTerminal"; source = "msstore" }, 
    @{name = "Microsoft.Azure.StorageExplorer" }, 
    @{name = "Google.Chrome  -e" },
    @{name = "Microsoft.VisualStudioCode" }, 
    @{name = "Microsoft.PowerToys" }
	
);
Foreach ($app in $apps) {
    $listApp = winget list --exact -q $app.name --accept-source-agreements 
    if (![String]::Join("", $listApp).Contains($app.name)) {
        Write-host "Installing:" $app.name
        if ($app.source -ne $null) {
            winget install --exact --silent $app.name --source $app.source --accept-package-agreements
        }
        else {
            winget install --exact --silent $app.name --accept-package-agreements
        }
    }
    else {
        Write-host "Skipping Install of " $app.name
    }
}

#Remove Apps
Write-Output "Removing Apps"

$apps = @(
	@{name = "*3DPrint*" },
	@{name = "Microsoft.MixedReality.Portal" },
	@{name = "Mail and Calendar" },
	@{name = "Xbox" },
	@{name = "Cortana" },
	@{name = "News" },
	@{name = "MSN Weather" },
	@{name = "Solitaire & Casual Games" },
	@{name = "Paint" },
	@{name = "Xbox TCUI" },
	@{name = "Game Bar" },
	@{name = "Xbox Identity Provider" },
	@{name = "Xbox Game Speech Window" },
	@{name = "Movies & TV" },
	@{name = "Microsoft Teams classic" },
	@{name = "Windows Maps" },
	@{name = "Windows Camera" },
	@{name = "Feedback Hub" },
	@{name = "Windows Sound Recorder" },
	@{name = "Phone Link" },
	@{name = "Microsoft Teams" }
 	@{name = "Groove Music" }
  	@{name = "Your Phone" }
   	@{name = "Xbox Game Bar Plugin" }
);
Foreach ($app in $apps)
{
  Write-host "Uninstalling:" $app.name
  winget uninstall --name $app.name
}

#Setup WSL
#wsl --install

﻿<#
.SYNOPSIS

Common tools

.EXAMPLE

#>

function Log-Date 
{
    ((get-date).ToUniversalTime()).ToString("yyyy-MM-dd HH:mm:ssZ")
}

function Propagate-EnvironmentUpdate
{
    if (-not ("win32.nativemethods" -as [type])) {
        # import sendmessagetimeout from win32
        add-type -Namespace Win32 -Name NativeMethods -MemberDefinition @"
[DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Auto)]
public static extern IntPtr SendMessageTimeout(
   IntPtr hWnd, uint Msg, UIntPtr wParam, string lParam,
   uint fuFlags, uint uTimeout, out UIntPtr lpdwResult);
"@
    }

    $HWND_BROADCAST = [intptr]0xffff;
    $WM_SETTINGCHANGE = 0x1a;
    $result = [uintptr]::zero

    # notify all windows of environment block change
    [win32.nativemethods]::SendMessageTimeout($HWND_BROADCAST, $WM_SETTINGCHANGE,
	    [uintptr]::Zero, "Environment", 2, 5000, [ref]$result);
}

<#
.SYNOPSIS

Add-DirectoryToEnvPathOnce
Add a directory to the path if it hasn't already been added

.DESCRIPTION

.EXAMPLE


#>
function Add-DirectoryToEnvPathOnce{
param (
    [string]
    $EnvVarToSet = 'PATH',

    [Parameter(Mandatory=$true)]
    [string]
    $Directory

    )

    $oldPath = [Environment]::GetEnvironmentVariable($EnvVarToSet, 'Machine')
    $match = '*' + $Directory + '*'
    $replace = $oldPath + ';' + $Directory 
    Write-Debug "OldPath = $Oldpath"
    Write-Debug "match = $match"
    Write-Debug "replace = $replace"
    if ( $oldpath -notlike $match )
    {
        [Environment]::SetEnvironmentVariable($EnvVarToSet, $replace, 'Machine')
        Write-Debug "Machine $EnvVarToSet updated"
    }

    # System Path may be different to remote PS starting environment, so check it separately
    if ( $env:Path -notlike $match )
    {
        $env:Path += ';' + $Directory
        Write-Debug "local Path updated"
    }

    Propagate-EnvironmentUpdate
}

function Connect-RemoteSession
{
    # Wait until PSSession is available
    while ($true)
    {
        "$(Log-Date) Waiting for remote PS connection"
        $Script:session = New-PSSession $Script:publicDNS -Credential $creds -ErrorAction SilentlyContinue
        if ($Script:session -ne $null)
        {
            break
        }

        Sleep -Seconds 10
    }

    Write-Output "$(Log-Date) $Script:instanceid remote PS connection obtained"
}

function MessageBox
{
param (
    [Parameter(Mandatory=$true)]
    [string]
    $Message
    )

    [console]::beep(500,1000)

    # OK and Cancel buttons
    Write-Output "$(Log-Date) $Message"
    $Response = [System.Windows.Forms.MessageBox]::Show("$Message", $Script:DialogTitle, 1 ) 
    if ( $Response -eq "Cancel" )
    {
        Write-Output "$(Log-Date) $Script:DialogTitle cancelled"
        throw
    }
}

function Install-VisualLansa
{
    ######################################
    # The VL IDE silent install has some quirks.
    # 1. The VL IDE install will stop on the launch of VL if Integrator is installed. So, We install them separately
    #    That way the lengthy VL install can get to the end.
    # 2. Integrator install stops with the Close button needing to be clicked. Its a fast install so spawn it off
    #    and continue with other parts of the installation process.
    # 3. Users are NOT created now as they become invalid  once the system is sysprepped. LANSA Quick Config configures this.
    ######################################

    # Installation settings
    $SettingsFile = "$Script:ScriptTempPath\LansaSettings.txt"
    $SettingsPassword = 'lansa'
    $installer_file = "$Script:DvdDir\Setup\FileTransfer.exe"

    ##########################################
    # Visual LANSA Install
    ##########################################

"SetupType=1
NewInstallType=1
InstallLevel=2
RootDirectory=C:\Program Files (x86)\Lansa
AllowRootDirectoryChange=True
VisualLansaType=6
FeatureVL=1
FeatureVLCore=1
FeatureWeb=1
FeatureWebEditor=1
FeatureWebAdministrator=1
FeatureWebServer=1
FeatureIISPlugin=1
FeatureWebImages=1
FeatureIntegrator=0
FeatureJSM=0
FeatureJSMProxy=0
FeatureUserAgent=0
FeatureRFI=0
FeatureIntegratorStudio=0
FeatureOpen=1
FeatureOpenCore=1
FeatureOpenSamples=1
FeatureOpenTranslationTables=1
FeatureConnect=1
StartFolderName=LANSA
64bitVLSupport=False
DatabaseAction=2
DatabaseNewInstance=False
DatabaseInstanceName=
DatabaseInstanceDirectory=C:\Program Files\Microsoft SQL Server
DatabaseDataDirectory=C:\Program Files\Microsoft SQL Server
DatabaseSharedDirectory=C:\Program Files\Microsoft SQL Server
DatabaseSAHidePassword=False
.DatabaseSAPassword=
DatabaseVersion=5
DatabaseTCPIPWorkaround=
DatabaseName=LANSA
DatabaseDirectory=C:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data
DatabaseLogDirectory=C:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data
DSNNew=True
DSNName=LANSA
DSNType=2
DSNDriverType=12
DSNDriverName=SQL Server Native Client 11.0
DSNServerName=(local)
DSNDatabaseName=LANSA
DSNUseTrustedConnections=True
DSNUserid=sa
.DSNPassword=112113200245048055164115207077090084060117130184210029036142038112134034166041252163025013128246
CompilerInstall=1
CompilerRootDirectory=C:\Program Files (x86)\LANSA\MicrosoftCompiler2010
HostRouteLUName=*LOCAL
HostRouteQualifier=localhost
HostRoutePortNumber=4545
HostRouteIpcOptions=1
ConnectToMaster=True
HostConnectIntegratedLogin=False
HostConnectUserid=pcxuser
.HostConnectPassword=
StopStartIIS=True
UseComputersName=True
NodeName=LANSA
InitializeDatabase=True
InitializePartitions=2
PartitionsToInitialize=DEX
SyncMaster=False
ImportExamplePartition=True
ImportExampleUserTask=False
ImportVLF=True
ImportDemo=True
RunDemo=False
ImportEnableForTheWeb=True
ImportClientDefinitions=True
InitializationLanguage=ENG
CCSID=1140
CustomCCSID=False
ClientToServerTranslationTable=ANSEBC1140
ServerToClientTranslationTable=EBC1140ANS
MessageFileName=DC@M01
HashCharacter=#
AtCharacter=@
DollarCharacter=$
LocalDataDirectory=C:\Program Files (x86)\LANSA\LANSA
ListenerAutomaticStartup=True
ListenerPortNumber=4545
UseridActionForVLWeb=0
UseridForVLWeb=PCXUSER2
.PasswordForVLWeb=161106219029123027150220095009114001171004042063034006087198091041059125101248041226025151149053
NetworkClientPrepareAutoUpgrade=True
NetworkClientServerName=
NetworkClientServerRootDirectory=
NetworkClientServerMapping=
UseridActionForWebServer=2
UseridForWebServer=PCXUSER2
.PasswordForWebServer=161106219029123027150220095009114001171004042063034006087198091041059125101248041226025151149053
WebsiteIISPlugin=016Default Web Site
WebsiteWebImages=Default Web Site
WebsiteJSM=Default Web Site
VirtualDirectoryAlias=cgi-bin
VirtualDirectory=
AutostartJSMAdministratorService=True
IntegratorPortNumber=4560
IntegratorAdminPortNumber=4561
UseridActionForJSM=0
UseridForJSM=PCXUSER2
.PasswordForJSM=161106219029123027150220095009114001171004042063034006087198091041059125101248041226025151149053 
JavaVersionForIntegrator=
OpenTranslationTableLansaProvided=1
OpenTranslationTable=1140
LansaLanguage=0
InstallLanguage=0
DatabaseSAPassword=sa+LANSA!" | out-file $SettingsFile

    Write-Output ("Installing Visual LANSA")
    # Start-Process -FilePath $installer_file -ArgumentList $Arguments -Wait
    # Piping output to anywhere causes powershell to wait until the process completes execution
    &$installer_file """$SettingsPassword""" """$SettingsFile""" | Write-Output
}

function Install-Integrator
{
    ##########################################
    # Integrator Install
    ##########################################

    $SettingsFile = "$Script:ScriptTempPath\IntegratorSettings.txt"
    $SettingsPassword = 'lansa'
    $installer_file = "$Script:DvdDir\Setup\FileTransfer.exe"

"SetupType=1
NewInstallType=1
InstallLevel=2
RootDirectory=C:\Program Files (x86)\LANSA
AllowRootDirectoryChange=True
VisualLansaType=6
FeatureVL=0
FeatureVLCore=0
FeatureWeb=0
FeatureWebEditor=0
FeatureWebAdministrator=0
FeatureWebServer=0
FeatureIISPlugin=0
FeatureWebImages=0
FeatureIntegrator=1
FeatureJSM=1
FeatureJSMProxy=1
FeatureUserAgent=1
FeatureRFI=1
FeatureIntegratorStudio=1
FeatureOpen=0
FeatureOpenCore=0
FeatureOpenSamples=0
FeatureOpenTranslationTables=0
FeatureConnect=0
StartFolderName=LANSA
64bitVLSupport=False
DatabaseAction=2
DatabaseNewInstance=False
DatabaseInstanceName=
DatabaseInstanceDirectory=C:\Program Files\Microsoft SQL Server
DatabaseDataDirectory=C:\Program Files\Microsoft SQL Server
DatabaseSharedDirectory=C:\Program Files\Microsoft SQL Server
DatabaseSAHidePassword=False
.DatabaseSAPassword=
DatabaseVersion=5
DatabaseTCPIPWorkaround=
DatabaseName=LANSA
DatabaseDirectory=C:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data
DatabaseLogDirectory=C:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Data
DSNNew=True
DSNName=LANSA
DSNType=2
DSNDriverType=12
DSNDriverName=SQL Server Native Client 11.0
DSNServerName=(local)
DSNDatabaseName=LANSA
DSNUseTrustedConnections=True
DSNUserid=sa
.DSNPassword=112113200245048055164115207077090084060117130184210029036142038112134034166041252163025013128246
CompilerInstall=1
CompilerRootDirectory=C:\Program Files (x86)\LANSA\MicrosoftCompiler2010
HostRouteLUName=*LOCAL
HostRouteQualifier=localhost
HostRoutePortNumber=4545
HostRouteIpcOptions=1
ConnectToMaster=True
HostConnectIntegratedLogin=False
HostConnectUserid=pcxuser
.HostConnectPassword=
StopStartIIS=True
UseComputersName=True
NodeName=LANSA
InitializeDatabase=True
InitializePartitions=2
PartitionsToInitialize=DEX
SyncMaster=False
ImportExamplePartition=True
ImportExampleUserTask=False
ImportVLF=True
ImportDemo=True
RunDemo=False
ImportEnableForTheWeb=True
ImportClientDefinitions=True
InitializationLanguage=ENG
CCSID=1140
CustomCCSID=False
ClientToServerTranslationTable=ANSEBC1140
ServerToClientTranslationTable=EBC1140ANS
MessageFileName=DC@M01
HashCharacter=#
AtCharacter=@
DollarCharacter=$
LocalDataDirectory=C:\Program Files (x86)\LANSA\LANSA
ListenerAutomaticStartup=True
ListenerPortNumber=4545
UseridActionForVLWeb=0
UseridForVLWeb=PCXUSER2
.PasswordForVLWeb=161106219029123027150220095009114001171004042063034006087198091041059125101248041226025151149053
NetworkClientPrepareAutoUpgrade=True
NetworkClientServerName=
NetworkClientServerRootDirectory=
NetworkClientServerMapping=
UseridActionForWebServer=2
UseridForWebServer=PCXUSER2
.PasswordForWebServer=161106219029123027150220095009114001171004042063034006087198091041059125101248041226025151149053
WebsiteIISPlugin=016Default Web Site
WebsiteWebImages=Default Web Site
WebsiteJSM=Default Web Site
VirtualDirectoryAlias=cgi-bin
VirtualDirectory=
AutostartJSMAdministratorService=True
IntegratorPortNumber=4560
IntegratorAdminPortNumber=4561
UseridActionForJSM=0
UseridForJSM=PCXUSER2
.PasswordForJSM=161106219029123027150220095009114001171004042063034006087198091041059125101248041226025151149053 
JavaVersionForIntegrator=
OpenTranslationTableLansaProvided=1
OpenTranslationTable=1140
LansaLanguage=0
InstallLanguage=0
DatabaseSAPassword=sa+LANSA!"| out-file $SettingsFile

    Write-Output ("Installing Integrator")
    # Start-Process -FilePath $installer_file -ArgumentList $Arguments -Wait
    # Piping output to anywhere causes powershell to wait until the process completes execution
    &$installer_file """$SettingsPassword""" """$SettingsFile""" | Write-Output
}

function New-Shortcut {
<#
.SYNOPSIS
	Creates a new shortcut (.lnk file) pointing at the specified file.

.DESCRIPTION
	The New-Shortcut script creates a shortcut pointing at the target in the location you specify.  You may specify the location as a folder path (which must exist), with a name for the new file (ending in .lnk), or you may specify one of the "SpecialFolder" names like "QuickLaunch" or "CommonDesktop" followed by the name.
	If you specify the path for the link file without a .lnk extension, the path is assumed to be a folder.
	
.EXAMPLE
	New-Shortcut C:\Windows\Notepad.exe
		Will make a shortcut to notepad in the current folder named "Notepad.lnk"
.EXAMPLE
	New-Shortcut C:\Windows\Notepad.exe QuickLaunch\Editor.lnk -Description "Run Notepad"
		Will make a shortcut to notepad on the QuickLaunch bar with the name "Editor.lnk" and the tooltip "Run Notepad"
.EXAMPLE
	New-Shortcut C:\Windows\Notepad.exe F:\User\
		Will make a shortcut to notepad in the F:\User\ folder with the name "Notepad.lnk"
.NOTE
   Partial dependency on Get-SpecialPath ( http://poshcode.org/858 )
#>
[CmdletBinding()]
param(
   [Parameter(Position=0,Mandatory=$true)]
	[string]$TargetPath,
	## Put the shortcut where you want: "Special Folder" names allowed!
   [Parameter(Position=1,Mandatory=$true)]
	[string]$LinkPath,
	## Extra parameters for the shortcut
	[string]$Arguments="",
	[string]$WorkingDirectory="",
	[string]$WindowStyle="Normal",
	[string]$IconLocation="",
	[string]$Hotkey="",
	[string]$Description="",
	[string]$Folder=""
)

# Values for Window Style:
# 1 - Normal    -- Activates and displays a window. If the window is minimized or maximized, the system restores it to its original size and position.
# 3 - Maximized -- Activates the window and displays it as a maximized window.
# 7 - Minimized -- Minimizes the window and activates the next top-level window.

if(!(Test-Path $TargetPath) -and !($TargetPath.Contains("://"))) {
   Write-Error "TargetPath must be an existing file for the link to point at (or a URL)"
 	return
}

function New-ShortCutFile {
    param(
		[string]$TargetPath=$(throw "Please specify a TargetPath for link to point to"),
		[string]$LinkPath=$(throw "must pass a path for the shortcut file"),
		[string]$Arguments="",
		[string]$WorkingDirectory=$(Split-Path $TargetPath -parent),
		[string]$WindowStyle="Normal",
		[string]$IconLocation="",
		[string]$Hotkey="",
		[string]$Description=$(Split-Path $TargetPath -Leaf)
	)

	if(-not ($TargetPath.Contains("://") -or (Test-Path (Split-Path (Resolve-Path $TargetPath) -parent)))) {
		Throw "Cannot create Shortcut: Parent folder does not exist"
	}
	if(-not (Test-Path variable:\global:WshShell)) { 
		$global:WshShell = New-Object -com "WScript.Shell" 
	}

	
	$Link = $global:WshShell.CreateShortcut($LinkPath)
	$Link.TargetPath = $TargetPath
	
	[IO.FileInfo]$LinkInfo = $LinkPath

	## Properties for file shortcuts only
	## If the $LinkPath ends in .url you can't set the arguments, icon, etc
	## if you make the same shortcut with a .lnk extension
	## you can still point it at a URL, but you can set hotkeys, icons, etc
	if( $LinkInfo.Extension -ne ".url" ) {
		$Link.WorkingDirectory = $WorkingDirectory
		## Validate $WindowStyle
		if($WindowStyle -is [string]) {
			if( $WindowStyle -like "Normal" ) { $WindowStyle = 1 }
			if( $WindowStyle -like "Maximized" ) { $WindowStyle = 3 }
			if( $WindowStyle -like "Minimized" ) { $WindowStyle = 7 }
		} 

		if( $WindowStyle -ne 1 -and $WindowStyle -ne 3 -and $WindowStyle -ne 7) { $WindowStyle = 1 }
		$Link.WindowStyle = $WindowStyle
	
		if($Hotkey.Length -gt 0 ) { $Link.HotKey = $Hotkey }
		if($Arguments.Length -gt 0 ) { $Link.Arguments = $Arguments }
		if($Description.Length -gt 0 ) { $Link.Description = $Description }
		if($IconLocation.Length -gt 0 ) { $Link.IconLocation = $IconLocation }
		
	}

  $Link.Save()
	Write-Output (get-item $LinkPath)
}


## If they didn't explicitly specify a folder
if($Folder.Length -eq 0) {
	if($LinkPath.Length -gt 0) { 
		$path = Split-Path $LinkPath -parent 
		[IO.FileInfo]$LinkInfo = $LinkPath
		if( $LinkInfo.Extension.Length -eq 0 ) {
			$Folder = $LinkPath
		} else {	
			# If the LinkPath is just a single word with no \ or extension...
			if($path.Length -eq 0) {
				$Folder = $Pwd
			} else {
				$Folder = $path
			}
		}
	}
	else 
	{ $Folder = $Pwd }
}

## If they specified a link path, check it for an extension
if($LinkPath.Length -gt 0) {
	$LinkPath = Split-Path $LinkPath -leaf
	[IO.FileInfo]$LinkInfo = $LinkPath
	if( $LinkInfo.Extension.Length -eq 0 ) {
		# If there's no extension, it must be a folder
		$Folder = $LinkPath
		$LinkPath = ""
	}
}
## If there's no Link name, make one up based on the target
if($LinkPath.Length -eq 0) {
	if($TargetPath.Contains("://")) {
		$LinkPath = "$($TargetPath.split('/')[2]).url"
	} else {
		[IO.FileInfo]$LinkInfo = $TargetPath
		$LinkPath = "$(([IO.FileInfo]$TargetPath).BaseName).lnk"
	}
}

## If the folder doesn't actually exist, maybe it's special...
if( -not (Test-Path $Folder)) {
	$morepath = "";
	if( $Folder.Contains("\") ) {
		$morepath = $Folder.SubString($Folder.IndexOf("\"))
		$Folder = $Folder.SubString(0,$Folder.IndexOf("\"))
	}
	$Folder = Join-Path (Get-SpecialPath $Folder) $morepath
	# or maybe they just screwed up
	trap { throw new-object ArgumentException "Cannot create shortcut: parent folder does not exist" }
}

$LinkPath = (Join-Path $Folder $LinkPath)
New-ShortCutFile $TargetPath $LinkPath $Arguments $WorkingDirectory $WindowStyle $IconLocation $Hotkey $Description
}

###############################################################################
## Get-SpecialPath Function (should be an external function in your profile, really)
##   This is an enhancement of [Environment]::GetFolderPath($folder) to add 
##   support for 8 additional folders, including QuickLaunch, and the common 
##   or "All Users" folders... while still supporting My Documents, Startup, etc.
##
function Get-SpecialPath 
{
   param([string]$folder)
   BEGIN {
      if ($folder.Length -gt 0) { 
         return $folder | &($MyInvocation.InvocationName); 
      } else {
         $WshShellFolders=@{CommonDesktop=0;CommonStartMenu=1;CommonPrograms=2;CommonStartup=3;PrintHood=6;Fonts=8;NetHood=9};
      }
   }
   PROCESS {
      if($_){
         ## Eliminate the options that are easiest to eliminate
         if($_ -eq "QuickLaunch") {
            $f1 = [Environment]::GetFolderPath("ApplicationData")
            return Join-Path $f1 "\Microsoft\Internet Explorer\Quick Launch"
            ## Test WshShellFolders first because it's easiest won't throw an exception
         } elseif($WshShellFolders.Contains($_)){
            if(-not (Test-Path variable:\global:WshShell)) { $global:WshShell = New-Object -com "WScript.Shell" }
            return (([string[]]$global:WshShell.SpecialFolders) -split " ")[$WshShellFolders[$_]]
         } else {
            ## Finally, try GetFolderPath, and if it throws, change the error message:
            trap
            {
               throw new-object system.componentmodel.invalidenumargumentexception $(
                  "Cannot convert value `"$_`" to type `"SpecialFolder`" due to invalid enumeration values. " +
                  "Specify one of the following enumeration values and try again. The possible enumeration values are: " +
                  "Desktop, Programs, Personal, MyDocuments, Favorites, Startup, Recent, SendTo, StartMenu, MyMusic, " +
                  "DesktopDirectory, MyComputer, Templates, ApplicationData, LocalApplicationData, InternetCache, Cookies, " +
                  "History, CommonApplicationData, System, ProgramFiles, MyPictures, CommonProgramFiles, CommonDesktop, " +
                  "CommonStartMenu, CommonPrograms, CommonStartup, PrintHood, Fonts, NetHood, QuickLaunch")
            }
            return [Environment]::GetFolderPath($_)
         }
      }
   }
}

function Add-TrustedSite
{
param(
    [Parameter(Mandatory=$true)]
    [String] 
    $SiteName
)
    $TrustedKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap\EscDomains\"
    $TrustedKeyPath = $TrustedKey + $SiteName
    New-Item "$TrustedKeyPath" -ErrorAction SilentlyContinue
    New-ItemProperty -Path "$TrustedKeyPath" -Name "http" -Value 2 -PropertyType DWord -ErrorAction SilentlyContinue
}
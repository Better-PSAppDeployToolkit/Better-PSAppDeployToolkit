function Execute-MSI {
<#
.SYNOPSIS
	Executes msiexec.exe to perform the following actions for MSI & MSP files and MSI product codes: install, uninstall, patch, repair, active setup.
.DESCRIPTION
	Executes msiexec.exe to perform the following actions for MSI & MSP files and MSI product codes: install, uninstall, patch, repair, active setup.
	If the -Action parameter is set to "Install" and the MSI is already installed, the function will exit.
	Sets default switches to be passed to msiexec based on the preferences in the XML configuration file.
	Automatically generates a log file name and creates a verbose log file for all msiexec operations.
	Expects the MSI or MSP file to be located in the "Files" sub directory of the App Deploy Toolkit. Expects transform files to be in the same directory as the MSI file.
.PARAMETER Action
	The action to perform. Options: Install, Uninstall, Patch, Repair, ActiveSetup.
.PARAMETER Path
	The path to the MSI/MSP file or the product code of the installed MSI.
.PARAMETER Transform
	The name of the transform file(s) to be applied to the MSI. The transform file is expected to be in the same directory as the MSI file. Multiple transforms have to be separated by a semi-colon.
.PARAMETER Patch
	The name of the patch (msp) file(s) to be applied to the MSI for use with the "Install" action. The patch file is expected to be in the same directory as the MSI file. Multiple patches have to be separated by a semi-colon.
.PARAMETER Parameters
	Overrides the default parameters specified in the XML configuration file. Install default is: "REBOOT=ReallySuppress /QB!". Uninstall default is: "REBOOT=ReallySuppress /QN".
.PARAMETER AddParameters
	Adds to the default parameters specified in the XML configuration file. Install default is: "REBOOT=ReallySuppress /QB!". Uninstall default is: "REBOOT=ReallySuppress /QN".
.PARAMETER SecureParameters
	Hides all parameters passed to the MSI or MSP file from the toolkit Log file.
.PARAMETER LoggingOptions
	Overrides the default logging options specified in the XML configuration file. Default options are: "/L*v".
.PARAMETER LogName
	Overrides the default log file name. The default log file name is generated from the MSI file name. If LogName does not end in .log, it will be automatically appended.
	For uninstallations, by default the product code is resolved to the DisplayName and version of the application.
.PARAMETER WorkingDirectory
	Overrides the working directory. The working directory is set to the location of the MSI file.
.PARAMETER SkipMSIAlreadyInstalledCheck
	Skips the check to determine if the MSI is already installed on the system. Default is: $false.
.PARAMETER IncludeUpdatesAndHotfixes
	Include matches against updates and hotfixes in results.
.PARAMETER NoWait
	Immediately continue after executing the process.
.PARAMETER PassThru
	Returns ExitCode, STDOut, and STDErr output from the process.
.PARAMETER IgnoreExitCodes
	List the exit codes to ignore or * to ignore all exit codes.
.PARAMETER PriorityClass	
	Specifies priority class for the process. Options: Idle, Normal, High, AboveNormal, BelowNormal, RealTime. Default: Normal
.PARAMETER ExitOnProcessFailure
	Specifies whether the function should call Exit-Script when the process returns an exit code that is considered an error/failure. Default: $true
.PARAMETER RepairFromSource
	Specifies whether we should repair from source. Also rewrites local cache. Default: $false
.PARAMETER ContinueOnError
	Continue if an error occured while trying to start the process. Default: $false.
.EXAMPLE
	Execute-MSI -Action 'Install' -Path 'Adobe_FlashPlayer_11.2.202.233_x64_EN.msi'
	Installs an MSI
.EXAMPLE
	Execute-MSI -Action 'Install' -Path 'Adobe_FlashPlayer_11.2.202.233_x64_EN.msi' -Transform 'Adobe_FlashPlayer_11.2.202.233_x64_EN_01.mst' -Parameters '/QN'
	Installs an MSI, applying a transform and overriding the default MSI toolkit parameters
.EXAMPLE
	[psobject]$ExecuteMSIResult = Execute-MSI -Action 'Install' -Path 'Adobe_FlashPlayer_11.2.202.233_x64_EN.msi' -PassThru
	Installs an MSI and stores the result of the execution into a variable by using the -PassThru option
.EXAMPLE
	Execute-MSI -Action 'Uninstall' -Path '{26923b43-4d38-484f-9b9e-de460746276c}'
	Uninstalls an MSI using a product code
.EXAMPLE
	Execute-MSI -Action 'Patch' -Path 'Adobe_Reader_11.0.3_EN.msp'
	Installs an MSP
.NOTES
.LINK
	http://psappdeploytoolkit.com
#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$false)]
		[ValidateSet('Install','Uninstall','Patch','Repair','ActiveSetup')]
		[string]$Action = 'Install',
		[Parameter(Mandatory=$true,HelpMessage='Please enter either the path to the MSI/MSP file or the ProductCode')]
		[ValidateScript({($_ -match $MSIProductCodeRegExPattern) -or ('.msi','.msp' -contains [IO.Path]::GetExtension($_))})]
		[Alias('FilePath')]
		[string]$Path,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
		[string]$Transform,
		[Parameter(Mandatory=$false)]
		[Alias('Arguments')]
		[ValidateNotNullorEmpty()]
		[string]$Parameters,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
		[string]$AddParameters,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
		[switch]$SecureParameters = $false,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
		[string]$Patch,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
		[string]$LoggingOptions,
		[Parameter(Mandatory=$false)]
		[Alias('LogName')]
		[string]$private:LogName,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
		[string]$WorkingDirectory,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
		[switch]$SkipMSIAlreadyInstalledCheck = $false,
		[Parameter(Mandatory=$false)]
		[switch]$IncludeUpdatesAndHotfixes = $false,
		[Parameter(Mandatory=$false)]
		[switch]$NoWait = $false,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
		[switch]$PassThru = $false,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
		[string]$IgnoreExitCodes,
		[Parameter(Mandatory=$false)]
		[ValidateSet('Idle', 'Normal', 'High', 'AboveNormal', 'BelowNormal', 'RealTime')]
		[Diagnostics.ProcessPriorityClass]$PriorityClass = 'Normal',
		[Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
		[boolean]$ExitOnProcessFailure = $true,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
		[boolean]$RepairFromSource = $false,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
		[boolean]$ContinueOnError = $false
	)

	begin {
		## Get the name of this function and write header
		$CmdletName = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName $CmdletName -CmdletBoundParameters $PSBoundParameters -Header
	}

	process {
		## If the path matches a product code
		if ($Path -match $MSIProductCodeRegExPattern) {
			#  Set variable indicating that $Path variable is a Product Code
			$PathIsProductCode = $true

			#  Resolve the product code to a publisher, application name, and version
			Write-Log -Message 'Resolving product code to a publisher, application name, and version.' -Source ${CmdletName}

			$GetInstalledApplicationSplat = @{
				ProductCode               = $path
				IncludeUpdatesAndHotfixes = $IncludeUpdatesAndHotfixes
			}

			$productCodeNameVersion = Get-InstalledApplication @GetInstalledApplicationSplat | Select-Object -Property 'Publisher', 'DisplayName', 'DisplayVersion' -First 1 -ErrorAction 'SilentlyContinue'

			#  Build the log file name
			If (-not $LogName) {
				$LogName = $Path #  set it to the path by default
				If ($productCodeNameVersion) {
					$LogNameParts = (
						$productCodeNameVersion.Publisher,
						$productCodeNameVersion.DisplayName, 
						$productCodeNameVersion.DisplayVersion
					)

					$LogName = (Remove-InvalidFileNameChars -Name ($LogNameParts | Join-String -Separator "_")) -Replace ' ',''
				}
			}
		} else {
			#  Get the log file name without file extension
			if (-not $LogName) { 
				$LogName = ([IO.FileInfo]$Path).BaseName 
			} elseif (('.log','.txt') -Contains [IO.Path]::GetExtension($LogName)) { 
				$LogName = [IO.Path]::GetFileNameWithoutExtension($LogName) 
			}
		}

		if ($ConfigToolkitCompressLogs) {
			$LogPathDir = $LogTempFolder
		} else {
			## Create the Log directory if it doesn't already exist
			if (-not (Test-Path -LiteralPath $ConfigMSILogDir -PathType 'Container' -ErrorAction 'SilentlyContinue')) {
				New-Item -Path $ConfigMSILogDir -ItemType 'Directory' -ErrorAction 'SilentlyContinue'
			}

			$LogPathDir = $ConfigMSILogDir
		}
		## Build the log file path
		$LogPath = Join-Path -Path $LogPathDir -ChildPath $LogName

		## Set the installation Parameters
		if ($deployModeSilent) {
			$msiInstallDefaultParams = $configMSISilentParams
			$msiUninstallDefaultParams = $configMSISilentParams
		} else {
			$msiInstallDefaultParams = $configMSIInstallParams
			$msiUninstallDefaultParams = $configMSIUninstallParams
		}

		## Build the MSI Parameters
		switch ($Action) {
			'Install' { 
				$Option = '/i'; 
				$MsiLogFile = "$LogPath" + '_Install'; 
				$MsiDefaultParams = $MsiInstallDefaultParams 
			}
			'Uninstall' { 
				$Option = '/x'; 
				$MsiLogFile = "$LogPath" + '_Uninstall'; 
				$MsiDefaultParams = $MsiUninstallDefaultParams 
			}
			'Patch' { 
				$Option = '/update'; 
				$MsiLogFile = "$LogPath" + '_Patch'; 
				$MsiDefaultParams = $MsiInstallDefaultParams 
			}
			'Repair' { 
				$Option = '/f'; 
				if ($RepairFromSource) {
					$Option += "v" 
				} 
				$MsiLogFile = "$LogPath" + '_Repair';
				$MsiDefaultParams = $MsiInstallDefaultParams 
			}
			'ActiveSetup' { 
				$Option = '/fups'; 
				$MsiLogFile = "$LogPath" + '_ActiveSetup' 
			}
		}

		## Append ".log" to the MSI logfile path and enclose in quotes
		if ([IO.Path]::GetExtension($MsiLogFile) -ne '.log') {
			$MsiLogFile = "`"$MsiLogFile.log`""
		}

		## If the MSI is in the Files directory, set the full path to the MSI
		if (Test-Path -LiteralPath (Join-Path -Path $DirFiles -ChildPath $Path -ErrorAction 'SilentlyContinue') -PathType 'Leaf' -ErrorAction 'SilentlyContinue') {
			$MsiFile = Join-Path -Path $DirFiles -ChildPath $Path
		} elseif (Test-Path -LiteralPath $Path -ErrorAction 'SilentlyContinue') {
			$MsiFile = (Get-Item -LiteralPath $Path).FullName
		} elseif ($PathIsProductCode) {
			$MsiFile = $Path
		} else {
			Write-Log -Message "Failed to find MSI file [$Path]." -Severity 3 -Source $CmdletName
			if (-not $ContinueOnError) {
				throw "Failed to find MSI file [$Path]."
			}
			continue
		}

		## Set the working directory of the MSI
		if ((-not $PathIsProductCode) -and (-not $WorkingDirectory)) {
			$WorkingDirectory = Split-Path -Path $MsiFile -Parent 
		}

		#TODO: the two ifs are literally the same code => funciton or smth?

		## Enumerate all transforms specified, qualify the full path if possible and enclose in quotes
		if ($Transform) {
			$Transforms = $Transform -replace "`"","" -split ';'
			for ($i = 0; $i -lt $Transforms.Length; $i++) {
				$FullPath = Join-Path -Path (Split-Path -Path $MsiFile -Parent) -ChildPath $Transforms[$i].Replace('.\','')
				If ($FullPath -and (Test-Path -LiteralPath $FullPath -PathType 'Leaf')) {
					$Transforms[$i] = $FullPath
				}
			}
			$MstFile = "`"$($Transforms -join ';')`""
		}

		## Enumerate all patches specified, qualify the full path if possible and enclose in quotes
		if ($Patch) {
			$Patches = $Patch -replace "`"","" -split ';'
			for ($i = 0; $i -lt $Patches.Length; $i++) {
				$FullPath = Join-Path -Path (Split-Path -Path $MsiFile -Parent) -ChildPath $Patches[$i].Replace('.\','')
				If ($FullPath -and (Test-Path -LiteralPath $FullPath -PathType 'Leaf')) {
					$Patches[$i] = $FullPath
				}
			}
			$MspFile = "`"$($Patches -join ';')`""
		}

		## Get the ProductCode of the MSI
		if ($PathIsProductCode) {
			$MSIProductCode = $Path
		} elseif ([IO.Path]::GetExtension($MsiFile) -eq '.msi') {
			try {
				$GetMsiTablePropertySplat = @{ 
					Path = $MsiFile
					Table = 'Property'
					ContinueOnError = $false 
				}

				if ($Transforms) { 
					$GetMsiTablePropertySplat.Add( 'TransformPath', $Transforms ) 
				}

				$MSIProductCode = Get-MsiTableProperty @GetMsiTablePropertySplat | Select-Object -ExpandProperty 'ProductCode' -ErrorAction 'Stop'
			}
			catch {
				Write-Log -Message "Failed to get the ProductCode from the MSI file. Continue with requested action [$Action]..." -Source $CmdletName
			}
		}

		## Enclose the MSI file in quotes to avoid issues with spaces when running msiexec
		$MsiFile = "`"$MsiFile`""

		## Start building the MsiExec command line starting with the base action and file
		$ArgsMSI = "$Option $MsiFile"
		#  Add MST
		if ($Transform) {
			$ArgsMSI = "$ArgsMSI TRANSFORMS=$MstFile TRANSFORMSSECURE=1" 
		}

		#  Add MSP
		if ($Patch) { 
			$ArgsMSI = "$ArgsMSI PATCH=$mspFile" 
		}

		#  Replace default parameters if specified.
		if ($Parameters) { 
			$ArgsMSI = "$ArgsMSI $Parameters" 
		} else { 
			$ArgsMSI = "$ArgsMSI $msiDefaultParams" 
		}
		
		#  Add reinstallmode and reinstall variable for Patch
		if ($Action -eq 'Patch') {
			$ArgsMSI += " REINSTALLMODE=ecmus REINSTALL=ALL"
		}
		
		#  Append parameters to default parameters if specified.
		if ($AddParameters) {
			$argsMSI = "$argsMSI $AddParameters" 
		}
		
		#  Add custom Logging Options if specified, otherwise, add default Logging Options from Config file
		if ($LoggingOptions) { 
			$argsMSI = "$argsMSI $LoggingOptions $msiLogFile" 
		} else { 
			$argsMSI = "$argsMSI $configMSILoggingOptions $msiLogFile" 
		}

		## Check if the MSI is already installed. If no valid ProductCode to check, then continue with requested MSI action.
		if ($MSIProductCode) {
			$IsMsiInstalled = $false
			if (-not $SkipMSIAlreadyInstalledCheck) {
				$GetInstalledApplicationSplat = @{
					ProductCode = $MSIProductCode
				}

				if ($IncludeUpdatesAndHotfixes) {
					GetInstalledApplicationSplat.Add("IncludeUpdatesAndHotfixes", $true)
				}

				$MsiInstalled = Get-InstalledApplication @GetInstalledApplicationSplat

				if ($MsiInstalled) { 
					$IsMsiInstalled = $true 
				}
			}
		} else {
			$IsMsiInstalled = $Action -neq 'Install'
		}

		if (($IsMsiInstalled) -and ($Action -eq 'Install')) {
			Write-Log -Message "The MSI is already installed on this system. Skipping action [$Action]..." -Source ${CmdletName}
		} elseif (((-not $IsMsiInstalled) -and ($Action -eq 'Install')) -or ($IsMsiInstalled)) {
			Write-Log -Message "Executing MSI action [$Action]..." -Source ${CmdletName}
			
			#  Build the hashtable with the options that will be passed to Execute-Process using splatting
			$ExecuteProcessSplat =  @{
				Path                 = $exeMsiexec
				Parameters           = $argsMSI
				WindowStyle          = 'Normal'
				ExitOnProcessFailure = $ExitOnProcessFailure
				ContinueOnError      = $ContinueOnError
			}

			if ($WorkingDirectory) { 
				$ExecuteProcessSplat.Add('WorkingDirectory', $WorkingDirectory) 
			}

			if ($SecureParameters) {
				$ExecuteProcessSplat.Add('SecureParameters', $SecureParameters) 
			}

			if ($PassThru) { 
				$ExecuteProcessSplat.Add('PassThru', $PassThru) 
			}

			if ($IgnoreExitCodes) {  
				$ExecuteProcessSplat.Add('IgnoreExitCodes', $IgnoreExitCodes) 
			}

			if ($PriorityClass) {  
				$ExecuteProcessSplat.Add('PriorityClass', $PriorityClass) 
			}

			if ($NoWait) { 
				$ExecuteProcessSplat.Add('NoWait', $NoWait) 
			}

			$ExecuteResults = Execute-Process @ExecuteProcessSplat

			#  Refresh environment variables for Windows Explorer process as Windows does not consistently update environment variables created by MSIs
			Update-Desktop
		} else {
			Write-Log -Message "The MSI is not installed on this system. Skipping action [$Action]..." -Source $CmdletName
		}
	}

	end {
		if ($PassThru) { 
			Write-Output -InputObject $ExecuteResults 
		}
		
		Write-FunctionHeaderOrFooter -CmdletName $CmdletName -Footer
	}
}
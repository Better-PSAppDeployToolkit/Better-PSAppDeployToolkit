function Copy-File {
<#
.SYNOPSIS
	Copy a file or group of files to a destination path.
.DESCRIPTION
	Copy a file or group of files to a destination path.
.PARAMETER Path
	Path of the file to copy.
.PARAMETER Destination
	Destination Path of the file to copy.
.PARAMETER Recurse
	Copy files in subdirectories.
.PARAMETER Flatten
	Flattens the files into the root destination directory.
.PARAMETER ContinueOnError
	Continue if an error is encountered. This will continue the deployment script, but will not continue copying files if an error is encountered. Default is: $true.
.PARAMETER ContinueFileCopyOnError
	Continue copying files if an error is encountered. This will continue the deployment script and will warn about files that failed to be copied. Default is: $false.
.EXAMPLE
	Copy-File -Path "$dirSupportFiles\MyApp.ini" -Destination "$envWinDir\MyApp.ini"
.EXAMPLE
	Copy-File -Path "$dirSupportFiles\*.*" -Destination "$envTemp\tempfiles"
	Copy all of the files in a folder to a destination folder.
.NOTES
.LINK
	http://psappdeploytoolkit.com
#>
	[CmdletBinding()]
	param (
		[Parameter(Mandatory=$true)]
		[ValidateNotNullorEmpty()]
		[string[]]$Path,
		[Parameter(Mandatory=$true)]
		[ValidateNotNullorEmpty()]
		[string]$Destination,
		[Parameter()] #TODO: can this go if empty?
		[switch]$Recurse = $false,
		[Parameter()] #TODO: can this go if empty?
		[switch]$Flatten,
		[Parameter()] #TODO: can this go if empty?
		[ValidateNotNullOrEmpty()]
		[boolean]$ContinueOnError = $true,
		[ValidateNotNullOrEmpty()]
		[boolean]$ContinueFileCopyOnError = $false
	)

	begin {
		## Get the name of this function and write header
		$CmdletName = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName $CmdletName -CmdletBoundParameters $PSBoundParameters -Header
	}

	process {
		try {
			if (-not (Test-Path -LiteralPath $Destination -PathType 'Container')) {
				Write-Log -Message "Destination folder does not exist, creating destination folder [$Destination]." -Source $CmdletName
				New-Item -Path $Destination -Type 'Directory' -Force -ErrorAction 'Stop'
			}

			if ($Flatten) {
				Write-Log -Message "Copying file(s) recursively=[$Recurse] in path [$Path] to destination [$Destination] root folder, flattened." -Source $CmdletName
				
				if ($Recurse) {
					$ChildPaths = Get-ChildItem -Path $Path -Recurse | Select FullName
				} else {
					$ChildPaths = ($Path)
				}

				foreach ($ChildPath in $ChildPaths) {
					if ($ChildPath.PSIsContainer) {
						continue
					}
					
					$CopyItemSplat = @{
						Path        = $ChildPath
						Destination = $Destination
						Force       = $true
					}

					if ($ContinueFileCopyOnError) {
						$CopyItemSplat["ErrorAction"] = "SilentlyContinue"
					}else{
						$CopyItemSplat["ErrorAction"] = "Stop"
					}

					Copy-Item @CopyItemSplat -ErrorVariable FileCopyError
				}
			} else {
				$null = $FileCopyError #TODO: idk what this does so im keeping it
				Write-Log -Message "Copying file(s) recursively in path [$Path] to destination [$Destination]." -Source $CmdletName
					
				$CopyItemSplat = @{
					Path = $Path
					Destination = $Destination
					Force = $true
					Recurse = $Recurse
				}

				if ($ContinueFileCopyOnError) {
					$CopyItemSplat["ErrorAction"] = "SilentlyContinue"
				}else{
					$CopyItemSplat["ErrorAction"] = "Stop"
				}

				Copy-Item @CopyItemSplat -ErrorVariable FileCopyError
			}

			if ((-not $ContinueFileCopyOnError) -and $FileCopyError) {
				Write-Log -Message "The following warnings were detected while copying file(s) in path [$Path] to destination [$Destination]. `r`n$FileCopyError" -Severity 2 -Source $CmdletName
			} else {
				Write-Log -Message "File copy completed successfully." -Source $CmdletName
			}
		} catch {
			Write-Log -Message "Failed to copy file(s) in path [$Path] to destination [$Destination]. `r`n$(Resolve-Error)" -Severity 3 -Source $CmdletName
			
			if (-not $ContinueOnError) {
				throw "Failed to copy file(s) in path [$Path] to destination [$Destination]: $($_.Exception.Message)"
			}
		}
	}

	end {
		Write-FunctionHeaderOrFooter -CmdletName $CmdletName -Footer
	}
}
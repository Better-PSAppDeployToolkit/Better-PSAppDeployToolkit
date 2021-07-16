function Disable-TerminalServerInstallMode {
<#
.SYNOPSIS
	Changes to user install mode for Remote Desktop Session Host/Citrix servers.
.DESCRIPTION
	Changes to user install mode for Remote Desktop Session Host/Citrix servers.
.PARAMETER ContinueOnError
	Continue if an error is encountered. Default is: $true.
.EXAMPLE
	Disable-TerminalServerInstallMode
.NOTES
.LINK
	http://psappdeploytoolkit.com
#>
	[CmdletBinding()]
	param (
		[ValidateNotNullorEmpty()]
		[boolean]$ContinueOnError = $true
	)

	begin {
		## Get the name of this function and write header
		$CmdletName = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionInfo -CmdletName $CmdletName -CmdletBoundParameters $PSBoundParameters -Header
	}

	process {
		try {
			Write-Log -Message 'Changing terminal server into user execute mode...' -Source $CmdletName
			$terminalServerResult = & "$envWinDir\System32\change.exe" User /Execute

			if ($global:LastExitCode -ne 1) {
				 throw $terminalServerResult 
			}
		} catch {
			Write-Log -Message "Failed to change terminal server into user execute mode. `r`n$(Resolve-Error) " -Severity 3 -Source $CmdletName
			if (-not $ContinueOnError) {
				throw "Failed to change terminal server into user execute mode: $($_.Exception.Message)"
			}
		}
	}
  
	end {
		Write-FunctionInfo -CmdletName $CmdletName -Footer
	}
}
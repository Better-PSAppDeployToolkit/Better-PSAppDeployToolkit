function Close-InstallationProgress {
<#
.SYNOPSIS
	Closes the dialog created by Show-InstallationProgress.
.DESCRIPTION
	Closes the dialog created by Show-InstallationProgress.
	This function is called by the Exit-Script function to close a running instance of the progress dialog if found.
.PARAMETER WaitingTime
	How many seconds to wait, at most, for the InstallationProgress window to be initialized, before the function returns, without closing anything. Range: 1 - 60  Default: 5
.EXAMPLE
	Close-InstallationProgress
.NOTES
	This is an internal script function and should typically not be called directly.
.LINK
	http://psappdeploytoolkit.com
#>
	[CmdletBinding()]
	param (
		[Parameter(Mandatory=$false)]
		[ValidateRange(1,60)]
		[int]$WaitingTime = 5
	)

	begin {
		## Get the name of this function and write header
		$CmdletName = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionInfo -CmdletName $CmdletName -CmdletBoundParameters $PSBoundParameters -Header
	}

	process {
		if ($deployModeSilent) {
			Write-Log -Message "Bypassing Close-InstallationProgress [Mode: $deployMode]" -Source $CmdletName
			return
		}

		# Check whether the window has been created
		if (-not $script:ProgressSyncHash.Window.IsInitialized) {
			Write-Log -Message "The installation progress dialog does not exist. Waiting up to $WaitingTime seconds..." -Source ${CmdletName}

			#wait for up to $WaitingTime seconds if the window does not exist
	
			$Timeout = $WaitingTime
			while ($Timeout -gt 0) {
				if ($script:ProgressSyncHash.Window.IsInitialized) {
					break
				}
				$Timeout -= 1
				Start-Sleep -Seconds 1
			}
			
			# Return if we still have no window
			if (-not $script:ProgressSyncHash.Window.IsInitialized) {
				Write-Log -Message "The installation progress dialog was not created within $WaitingTime seconds." -Source ${CmdletName} -Severity 2
				return
			}
		}
		
		# If the thread is suspended, resume it
		if ($script:ProgressSyncHash.Window.Dispatcher.Thread.ThreadState -band [system.threading.threadstate]::Suspended) {
			Write-Log -Message 'The thread for the installation progress dialog is suspended. Resuming the thread.' -Source $CmdletName
			try {
				$script:ProgressSyncHash.Window.Dispatcher.Thread.Resume()
			} catch {
				Write-Log -Message 'Failed to resume the thread for the installation progress dialog.' -Source $CmdletName -Severity 2
			}
		}

		# If the thread is changing its state, wait
		if (($script:ProgressSyncHash.Window.Dispatcher.Thread.ThreadState -band [system.threading.threadstate]::Aborted)
			-or ($script:ProgressSyncHash.Window.Dispatcher.Thread.ThreadState -band [system.threading.threadstate]::AbortRequested)
			-or ($script:ProgressSyncHash.Window.Dispatcher.Thread.ThreadState -band [system.threading.threadstate]::StopRequested)
			-or ($script:ProgressSyncHash.Window.Dispatcher.Thread.ThreadState -band [system.threading.threadstate]::Unstarted) 
			-or ($script:ProgressSyncHash.Window.Dispatcher.Thread.ThreadState -band [system.threading.threadstate]::WaitSleepJoin)) {
			
			Write-Log -Message "The thread for the installation progress dialog is changing its state. Waiting up to $WaitingTime seconds..." -Source $CmdletName -Severity 2
			
			$Timeout = $WaitingTime
			while ($Timeout -gt 0) {
				if (-not (($script:ProgressSyncHash.Window.Dispatcher.Thread.ThreadState -band [system.threading.threadstate]::Aborted)
					-or ($script:ProgressSyncHash.Window.Dispatcher.Thread.ThreadState -band [system.threading.threadstate]::AbortRequested)
					-or ($script:ProgressSyncHash.Window.Dispatcher.Thread.ThreadState -band [system.threading.threadstate]::StopRequested)
					-or ($script:ProgressSyncHash.Window.Dispatcher.Thread.ThreadState -band [system.threading.threadstate]::Unstarted) 
					-or ($script:ProgressSyncHash.Window.Dispatcher.Thread.ThreadState -band [system.threading.threadstate]::WaitSleepJoin))) {
					break
				}
				$Timeout -= 1
				Start-Sleep -Seconds 1
			}

			# If the thread is running, stop it
			if ((-not ($script:ProgressSyncHash.Window.Dispatcher.Thread.ThreadState -band [system.threading.threadstate]::Stopped)) -and (-not ($script:ProgressSyncHash.Window.Dispatcher.Thread.ThreadState -band [system.threading.threadstate]::Unstarted))) {
				Write-Log -Message 'Closing the installation progress dialog.' -Source ${CmdletName}
				$script:ProgressSyncHash.Window.Dispatcher.InvokeShutdown()
			}
		}
	

		if ($script:ProgressRunspace) {
			# If the runspace is still opening, wait
			if (-not (($script:ProgressRunspace.RunspaceStateInfo.State -eq [system.management.automation.runspaces.runspacestate]::Opening)
				-or ($script:ProgressRunspace.RunspaceStateInfo.State -eq [system.management.automation.runspaces.runspacestate]::BeforeOpen))) {

				Write-Log -Message "The runspace for the installation progress dialog is still opening. Waiting up to $WaitingTime seconds..." -Source ${CmdletName} -Severity 2

				$Timeout = $WaitingTime
				while ($Timeout -gt 0) {
					if(($script:ProgressRunspace.RunspaceStateInfo.State -eq [system.management.automation.runspaces.runspacestate]::Opening)
						-or ($script:ProgressRunspace.RunspaceStateInfo.State -eq [system.management.automation.runspaces.runspacestate]::BeforeOpen)){
						break
					}
					
					$Timeout -= 1
					Start-Sleep -Seconds 1
				}
			}

			# If the runspace is opened, close it
			if ($script:ProgressRunspace.RunspaceStateInfo.State -eq [system.management.automation.runspaces.runspacestate]::Opened) {
				Write-Log -Message "Closing the installation progress dialog`'s runspace." -Source $CmdletName
				$script:ProgressRunspace.Close()
			}
		} else {
			Write-Log -Message 'The runspace for the installation progress dialog is already closed.' -Source $CmdletName -Severity 2
		}

		if ($script:ProgressSyncHash) {
			$script:ProgressSyncHash.Clear()
		}
	}
	end {
		Write-FunctionInfo -CmdletName $CmdletName -Footer
	}
}

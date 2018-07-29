$Global:a = "<style>"
$a = $a + "TABLE{border-width: 1px;border-style: solid;border-color: black;border-collapse: collapse;}"
$a = $a + "TH{border-width: 1px;padding: 10px;border-style: solid;border-color: black;}"
$a = $a + "TD{border-width: 1px;padding: 10px;border-style: solid;border-color: black;}"
$a = $a + "</style>"
Function Get-SecurityAudits
{
	param
	(
		[Parameter(ValueFromPipeline=$true,Mandatory=$false)]
		[String]$Computer = $env:computername
	)
	Try
	{
		$Reply = Test-Connection $Computer -Count 1| Select -expand Statuscode
	}
	Catch [system.exception]
	{
		Write-Host "Exception sending the ICMP request" -foregroundcolor red
		Write-Host "There was no ICMP reply to be heard" -foregroundcolor red
		Write-Host "`t+ Please check for network connectivity to: $computer.toupper()" -foregroundcolor red
		
	}
	Finally
	{
		If($Reply -eq 0)
		{
			$Computer.toupper()
			If($Computer -ne $env:computername) 
			{
				$RegServ = Get-Service remoteregistry -ComputerName $Computer
				If($RegServ.status -ne "Running")
				{
					Set-Service remoteregistry -ComputerName $Computer -status Running
				}
			}
			$events = get-eventlog security -computer $Computer | Where-Object {($_.instanceID -eq "4648") -and ($_.replacementstrings[5] -ne ($Computer + "`$"))} 
			ForEach($event in $events)
			{
				Add-Member -InputObject $event -MemberType NoteProperty -Name SourceIP -Value $event.replacementstrings[12]
				Add-Member -InputObject $event -MemberType NoteProperty -Name TargetUser -Value $event.replacementstrings[5]
			}
			$events |  ConvertTo-Html -Head "<H1>AD Audit Event Logs</H1>" -Body $a | Out-File C:\Users\$env:USERNAME\desktop\AuditedEvents.html
			If($LeaveServiceRunning = $false) #Stop the service if requested
			{
				Write-Host Turning RemoteRegistry service off...
				Get-WmiObject -Class Win32_Service | ?{$_.name -eq 'RemoteRegistry'} -ComputerName $Computer | Invoke-WmiMethod -Name StopService | out-null
			}
		}
	}
}

Get-SecurityAudits -Computer "S1"
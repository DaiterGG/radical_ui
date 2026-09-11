param(
	[Parameter(Mandatory = $true)]
	[int]$Seconds
)

if ($Seconds -lt 1) {
	throw "Seconds must be at least 1."
}

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$stdout = Join-Path $root "integrated_run.out.log"
$stderr = Join-Path $root "integrated_run.err.log"

Remove-Item $stdout, $stderr -ErrorAction SilentlyContinue
$process = Start-Process `
	-FilePath "cmd.exe" `
	-ArgumentList "/c", "call", "`"$root\run.bat`"" `
	-WorkingDirectory $root `
	-RedirectStandardOutput $stdout `
	-RedirectStandardError $stderr `
	-PassThru

try {
	Start-Sleep -Seconds $Seconds
}
finally {
	$processIds = [System.Collections.Generic.HashSet[int]]::new()
	[void]$processIds.Add($process.Id)

	do {
		$foundChild = $false
		foreach ($child in Get-CimInstance Win32_Process) {
			if ($processIds.Contains([int]$child.ParentProcessId)) {
				if ($processIds.Add([int]$child.ProcessId)) {
					$foundChild = $true
				}
			}
		}
	} while ($foundChild)

	foreach ($processId in $processIds) {
		$running = Get-Process -Id $processId -ErrorAction SilentlyContinue
		if ($running) {
			Stop-Process -Id $processId -Force -ErrorAction SilentlyContinue
		}
	}
}

Write-Output "Logs: $stdout"
Write-Output "Errors: $stderr"

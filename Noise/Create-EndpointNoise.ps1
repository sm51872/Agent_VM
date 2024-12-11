param (
    [switch] $Run,
    [switch] $Cleanup
)

# Load Configuration
$config = Get-Content $PSScriptRoot'\config.json' | Out-String | ConvertFrom-Json


function Write-Log {
    param (
        [string]$Message,
        [string]$Level = "INFO"
    )

    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $CallingFunction = $MyInvocation.MyCommand.Name
    $LogEntry = "$Timestamp - [$Level] - [$CallingFunction] - $Message"

    Add-Content -Path $config.logFile -Value $LogEntry
}


function New-RandomFilePath {
    param (
        [string] $Extension
    )

    # Check the store has been created
    if (!(Test-Path $config.store)) {
        New-Item -ItemType Directory -Path $config.store
    }

    $randomFileName = [System.IO.Path]::GetRandomFileName()

    # Combine the random file name with the provided extension
    $fullPath = Join-Path -Path $config.store -ChildPath "$randomFileName.$Extension"

    # Return the full path
    return $fullPath
}

function Run-Cleanup {
    Write-Log -Message "Deleting $((Get-ChildItem -File -Path $config.store | Measure-Object).Count) items."

    # Every hour, do some cleaning up.
    Remove-Item "$($config.store)\*"

    Stop-Service -Name $config.service.name

    $service = Get-WmiObject -Class Win32_Service -Filter "Name='$($config.service.name)'"
    $service.delete()

    Unregister-ScheduledTask -TaskName $config.task.name -Confirm:$false
}


function Invoke-Lnk {   
    $path = New-RandomFilePath -Extension ".lnk"
    
    Write-Log -Message "Creating LNK file $path"

    # Create the link object using the WScript.Shell CreateShortcut method
    $shell = New-Object -ComObject WScript.Shell
    $shortcut = $shell.CreateShortcut($path)
    $shortcut.TargetPath = $config.target
    $shortcut.Save()
}


function Invoke-Download {
    # Create a random path to save the file to, We'll delete this later.
    $path = New-RandomFilePath -Extension ".tmp"
    $url = $(Get-Random -InputObject $config.downloads.urls)

    Write-Log -Message "Downloading $url"

    try {
        $ProgressPreference = 'SilentlyContinue'
        Invoke-WebRequest -Uri $url -OutFile $path
    } catch {
        Write-Host "Failed to download file from $Url"
    }
}

function Invoke-DNS {
    $samples = Get-Random -Minimum 1 -Maximum 10

    Write-Log -Message "Running $samples DNS Queries"

    foreach($i in 1..$samples){
        $domain = $(Get-Random -InputObject $config.domains)

        try {
            Resolve-DnsName -Name $domain -ErrorAction Stop
        } catch {
            Write-Host "Failed to resolve $domain"
        }

        Start-Sleep -Seconds 3
    }
}

function Invoke-Edge {
    $samples = Get-Random -Minimum 1 -Maximum 10

    foreach($i in 1..$samples){
        $url = "https://www.$(Get-Random -InputObject $config.domains)"

        Write-Log -Message "Browsing to $url"

        Start-Process -FilePath "msedge" -ArgumentList $url
    
        Start-Sleep -Seconds 1
    }

    # Wait for a few seconds (adjust as needed)
    Start-Sleep -Seconds $(Get-Random -Minimum 5 -Maximum (20))

    # Close the Microsoft Edge windows
    Get-Process msedge | ForEach-Object { $_.CloseMainWindow() }
}


function Invoke-AutoRun {
    $Time = New-ScheduledTaskTrigger -At 12:00 -Once
    $User = $Env:UserName
    $PS = New-ScheduledTaskAction -Execute $config.task.execute
    Register-ScheduledTask -TaskName $config.task.name -Trigger $Time -User $User -Action $PS

    Write-Log -Message "Scheduled task $($config.task.name) created successfully!"

    # Remove the scheduled task after execution
    Unregister-ScheduledTask -TaskName $config.task.name -Confirm:$false
    Write-Log -Message "Scheduled task $($config.task.name) removed."
}


function Invoke-Process {
    $randomProcess = Get-Random -InputObject $config.processes

    Write-Log -Message "Starting $randomProcess"

    $process = Start-Process -FilePath $randomProcess -WindowStyle Hidden -PassThru
    Start-Sleep -Seconds 10
    Stop-Process -Id $process.Id
}


function Invoke-Service {
    # Create the service
    New-Service -Name $config.service.name -DisplayName $config.service.name -Description $config.service.description -BinaryPathName $config.service.binary
    
    Write-Log -Message "Creating service $($config.service.name)"
    
    Start-Service -Name $config.service.name
    Start-Sleep -Seconds 10

    Stop-Service -Name $config.service.name
    
    $service = Get-WmiObject -Class Win32_Service -Filter "Name='$($config.service.name)'"
    $service.delete()
}


function Invoke-WMI {
    Write-Log -Message "Running WMI queries"

    $namespace = "root\cimv2"
    $class = "Win32_OperatingSystem"
    $query = "SELECT * FROM $class"
    $osInfo = Get-WmiObject -Namespace $namespace -Query $query | Select-Object Caption, OSArchitecture, Version, LastBootUpTime

    $class = "Win32_Process"
    $query = "SELECT * FROM $class"
    $processes = Get-WmiObject -Namespace $namespace -Query $query | Select-Object Name, ProcessId 

    $result = Invoke-WmiMethod -Class Win32_Process -Name Create -ArgumentList "ping.exe 8.8.8.8"

    if ($result.ReturnValue -eq 0) {
        Write-Host "Process created successfully."
    } else {
        Write-Host "Failed to create process."
    }

    $class = "Win32_Service"
    $query = "SELECT * FROM $class WHERE Name='Spooler'"
    $wmiObject = Get-WmiObject -Namespace $namespace -Query $query
    $wmiObject | Invoke-WmiMethod -Name PauseService
    Start-Sleep -Seconds 10
    $wmiObject | Invoke-WmiMethod -Name ResumeService
}

if ($Run) {
    # Run a random invoke function.
    $functions = Get-ChildItem function:\ | Where-Object {$_.Name -like "Invoke*"}
    $randomFunction = Get-Random -InputObject $functions
    & $randomFunction.Name
}
elseif ($Cleanup) {
    # Cleanup any artifacts we may have created.
    Run-Cleanup
}
else {
    Write-Host "No function requested."
}

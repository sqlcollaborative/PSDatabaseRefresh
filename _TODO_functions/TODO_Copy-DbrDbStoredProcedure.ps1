function Copy-DbrDbStoredProcedure {

    <#
    .SYNOPSIS
        Copy the stored procedures

    .DESCRIPTION
        Copy the stored procedures in a database

    .PARAMETER SourceSqlInstance
        The source SQL Server instance or instances.

    .PARAMETER SourceSqlCredential
        Login to the target instance using alternative credentials. Windows and SQL Authentication supported. Accepts credential objects (Get-Credential)

    .PARAMETER DestinationSqlInstance
        The target SQL Server instance or instances.

    .PARAMETER DestinationSqlCredential
        Login to the target instance using alternative credentials. Windows and SQL Authentication supported. Accepts credential objects (Get-Credential)

    .PARAMETER Database
        Database to Copy the stored procedures from

    .PARAMETER Schema
        Filter based on schema

    .PARAMETER StoredProcedure
        Stored procedures to filter out

    .PARAMETER WhatIf
        Shows what would happen if the command were to run. No actions are actually performed.

    .PARAMETER Confirm
        Prompts you for confirmation before executing any changing operations within the command.

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

    .EXAMPLE
        Copy-DbrDbStoredProcedure -SqlInstance sqldb1 -Database DB1

        Copy all the stored procedures from the database

    .EXAMPLE
        Copy-DbrDbStoredProcedure -SqlInstance sqldb1 -Database DB1 -StoredProcedure PROC1, PROC2

        Copy all the stored procedures from the database with the name PROC1 and PROC2

    #>

    [CmdLetBinding(SupportsShouldProcess)]

    param(
        [parameter(Mandatory)]
        [DbaInstanceParameter]$SourceSqlInstance,
        [PSCredential]$SourceSqlCredential,
        [parameter(Mandatory)]
        [DbaInstanceParameter]$DestinationSqlInstance,
        [PSCredential]$DestinationSqlCredential,
        [parameter(Mandatory)]
        [string]$Database,
        [string[]]$Schema,
        [string[]]$StoredProcedure,
        [switch]$EnableException
    )

    begin {
        $progressId = 1

        $stopwatchObject = New-Object System.Diagnostics.Stopwatch

        $task = "Collecting stored procedures"

        Write-Progress -Id ($progressId + 2) -ParentId ($progressId + 1) -Activity $task
        try {
            $procedures = Get-DbaModule -SqlInstance $SourceSqlInstance -SqlCredential $SourceSqlCredential -Database $Database -Type StoredProcedure -ExcludeSystemObjects
            $procedures = $procedures | Sort-Object SchemaName, Name
        }
        catch {
            Stop-PSFFunction -Message "Could not retrieve stored procedures from source instance" -ErrorRecord $_ -Target $SourceSqlInstance
        }

        # Filter out the stored procedures based on schema
        if ($Schema) {
            $procedures = $procedures | Where-Object SchemaName -in $Schema
        }

        # Filter out the stored procedures based on name
        if ($StoredProcedure) {
            $procedures = $procedures | Where-Object Name -in $StoredProcedure
        }

        # Get the database
        try {
            $db = Get-DbaDatabase -SqlInstance $SourceSqlInstance -SqlCredential $SourceSqlCredential -Database $Database
        }
        catch {
            Stop-PSFFunction -Message "Could not retrieve database from source instance" -ErrorRecord $_ -Target $SourceSqlInstance
        }
    }

    process {
        if (Test-PSFFunctionInterrupt) { return }

        $totalObjects = $procedures.Count
        $objectStep = 0

        if ($totalObjects -ge 1) {
            if ($PSCmdlet.ShouldProcess("Copying stored procedures to database $Database")) {

                foreach ($procedure in $procedures) {
                    $objectStep++
                    $task = "Creating Stored Procedure(s)"
                    $operation = "Stored Procedure [$($procedure.SchemaName)].[$($procedure.Name)]"

                    $params = @{
                        Id               = ($progressId + 2)
                        ParentId         = ($progressId + 1)
                        Activity         = $task
                        Status           = "Progress-> Procedure $objectStep of $totalObjects"
                        PercentComplete  = $($objectStep / $totalObjects * 100)
                        CurrentOperation = $operation
                    }

                    $stopwatchObject.Start()

                    Write-Progress @params

                    Write-PSFMessage -Level Verbose -Message "Creating stored procedure [$($procedure.SchemaName)].[$($procedure.Name)] in $($Database)"

                    try {
                        $query = ($db.StoredProcedures | Where-Object { $_.Schema -eq $procedure.SchemaName -and $_.Name -eq $procedure.Name }) | Export-DbaScript -Passthru -NoPrefix | Out-String
                        Invoke-DbaQuery -SqlInstance $DestinationSqlInstance -SqlCredential $DestinationSqlCredential -Database $Database -Query $query -EnableException
                    }
                    catch {
                        Stop-PSFFunction -Message "Could not create procedure [$($procedure.SchemaName)].[$($procedure.Name)] in $($dbName)`n$_" -Target $procedure -ErrorRecord $_
                    }

                    $stopwatchObject.Stop()

                    [PSCustomObject]@{
                        SqlInstance    = $DestinationSqlInstance
                        Database       = $Database
                        ObjectType     = "Stored Procedure"
                        Parent         = $Database
                        Object         = "$($procedure.SchemaName).$($procedure.Name)"
                        Information    = $null
                        ElapsedSeconds = [int][Math]::Truncate($stopwatchObject.Elapsed.TotalSeconds)
                    }

                    $stopwatchObject.Reset()
                }
            }
        }
    }
}
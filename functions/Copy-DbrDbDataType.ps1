function Copy-DbrDbDataType {

    <#
    .SYNOPSIS
        Copy the user defined data types

    .DESCRIPTION
        Copy the user defined data types in a database

    .PARAMETER SourceSqlInstance
        The source SQL Server instance or instances.

    .PARAMETER SourceSqlCredential
        Login to the target instance using alternative credentials. Windows and SQL Authentication supported. Accepts credential objects (Get-Credential)

    .PARAMETER DestinationSqlInstance
        The target SQL Server instance or instances.

    .PARAMETER DestinationSqlCredential
        Login to the target instance using alternative credentials. Windows and SQL Authentication supported. Accepts credential objects (Get-Credential)

    .PARAMETER SourceDatabase
        Database to copy the user defined data types from

    .PARAMETER DestinationDatabase
        Database to copy the user defined data types to

    .PARAMETER Schema
        Filter based on schema

    .PARAMETER DataType
        Data type to filter out

    .PARAMETER Force
        If set, the command will remove any objects that are present prior to creating them

    .PARAMETER WhatIf
        Shows what would happen if the command were to run. No actions are actually performed.

    .PARAMETER Confirm
        Prompts you for confirmation before executing any changing operations within the command.

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

    .EXAMPLE
        Copy-DbrDbDataType -SqlInstance sqldb1 -Database DB1

        Copy all the user defined data types from the database

    .EXAMPLE
        Copy-DbrDbDataType -SqlInstance sqldb1 -Database DB1 -View VIEW1, VIEW2

        Copy all the user defined data types from the database with the name VIEW1 and VIEW2

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
        [string]$SourceDatabase,
        [string]$DestinationDatabase,
        [string[]]$Schema,
        [string[]]$DataType,
        [switch]$Force,
        [switch]$EnableException
    )

    begin {
        $progressId = 1

        # Check the parameters
        if (-not $DestinationDatabase) {
            Write-PSFMessage -Message "Setting destination database to '$($SourceDatabase)'" -Level Verbose
            $DestinationDatabase = $SourceDatabase
        }

        if (($DestinationDatabase -eq $SourceDatabase) -and ($SourceSqlInstance -eq $DestinationSqlInstance)) {
            Stop-PSFFunction -Message "Please enter a destination database when copying on the same instance" -Target $DestinationDatabase -EnableException:$EnableException
            return
        }

        # Get the database
        try {
            $sourceDb = Get-DbaDatabase -SqlInstance $SourceSqlInstance -SqlCredential $SourceSqlCredential -Database $SourceDatabase
        }
        catch {
            Stop-PSFFunction -Message "Could not retrieve database from source instance" -ErrorRecord $_ -Target $SourceSqlInstance -EnableException:$EnableException
        }

        try {
            $destDb = Get-DbaDatabase -SqlInstance $DestinationSqlInstance -SqlCredential $DestinationSqlCredential -Database $DestinationDatabase
        }
        catch {
            Stop-PSFFunction -Message "Could not retrieve database from destination instance" -ErrorRecord $_ -Target $DestinationSqlInstance -EnableException:$EnableException
        }


        $task = "Collecting user defined data types"

        Write-Progress -Id ($progressId + 2) -ParentId ($progressId + 1) -Activity $task

        # retrieve the data types
        try {
            [array]$dataTypes = $sourceDb.UserDefinedDataTypes | Sort-Object Schema, Name
        }
        catch {
            Stop-PSFFunction -Message "Could not retrieve user defined data types from source instance" -ErrorRecord $_ -Target $SourceSqlInstance -EnableException:$EnableException
        }

        if ($Schema) {
            [array]$dataTypes = $dataTypes | Where-Object Schema -in $Schema
        }

        if ($DataType) {
            [array]$dataTypes = $dataTypes | Where-Object Name -in $DataType
        }
    }

    process {
        if (Test-PSFFunctionInterrupt) { return }

        $totalObjects = $dataTypes.Count
        $objectStep = 0

        if ($totalObjects -ge 1) {
            if ($PSCmdlet.ShouldProcess("Copying user defined data types to database $Database")) {

                # Create the user defined data types
                foreach ($object in $dataTypes) {

                    if ($Force -and ($object.Name -in $destDb.UserDefinedDataTypes.Name)) {
                        $params = @{
                            SqlInstance   = $DestinationSqlInstance
                            SqlCredential = $DestinationSqlCredential
                            Database      = $DestinationDatabase
                            Schema        = $object.Schema
                            DataType      = $object.Name
                        }

                        Remove-DbrDbDataType @params
                    }

                    if ($object.Name -notin $destDb.UserDefinedDataTypes.Name) {
                        $objectStep++
                        $task = "Creating Data Type(s)"
                        $operation = "Data Type [$($object.Schema)].[$($object.Name)]"

                        $params = @{
                            Id               = ($progressId + 2)
                            ParentId         = ($progressId + 1)
                            Activity         = $task
                            Status           = "Progress-> Data Type $objectStep of $totalObjects"
                            PercentComplete  = $($objectStep / $totalObjects * 100)
                            CurrentOperation = $operation
                        }

                        Write-Progress @params

                        Write-PSFMessage -Level Verbose -Message "Creating data type [$($object.Schema)].[$($object.Name)] in $($destDb.Name)"

                        $query = ($dataTypes | Where-Object { $_.Schema -eq $object.Schema -and $_.Name -eq $object.Name }) | Export-DbaScript -Passthru -NoPrefix | Out-String

                        try {
                            $params = @{
                                SqlInstance     = $DestinationSqlInstance
                                SqlCredential   = $DestinationSqlCredential
                                Database        = $DestinationDatabase
                                Query           = $query
                                EnableException = $true
                            }

                            Invoke-DbaQuery @params
                        }
                        catch {
                            Stop-PSFFunction -Message "Could not execute script for data type $object" -ErrorRecord $_ -Target $view -EnableException:$EnableException
                        }

                        [PSCustomObject]@{
                            SourceSqlInstance      = $SourceSqlInstance
                            DestinationSqlInstance = $DestinationSqlInstance
                            SourceDatabase         = $SourceDatabase
                            DestinationDatabase    = $DestinationDatabase
                            ObjectType             = "User Defined Data Type"
                            Parent                 = $null
                            Object                 = "$($object.Schema).$($object.Name)"
                            Notes                  = $null
                        }
                    }
                    else {
                        Write-PSFMessage -Message "Data type [$($object.Schema)].[$($object.Name)] already exists. Skipping..." -Level Verbose
                    }
                }
            }
        }
        else {
            Write-PSFMessage -Message "No data types found" -Level Verbose
        }
    }
}
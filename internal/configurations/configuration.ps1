﻿<#
This is an example configuration file

By default, it is enough to have a single one of them,
however if you have enough configuration settings to justify having multiple copies of it,
feel totally free to split them into multiple files.
#>

<#
# Example Configuration
Set-PSFConfig -Module 'dbarefresh' -Name 'Example.Setting' -Value 10 -Initialize -Validation 'integer' -Handler { } -Description "Example configuration setting. Your module can then use the setting using 'Get-PSFConfigValue'"
#>

Set-PSFConfig -Module 'dbarefresh' -Name 'Import.DoDotSource' -Value $false -Initialize -Validation 'bool' -Description "Whether the module files should be dotsourced on import. By default, the files of this module are read as string value and invoked, which is faster but worse on debugging."
Set-PSFConfig -Module 'dbarefresh' -Name 'Import.IndividualFiles' -Value $false -Initialize -Validation 'bool' -Description "Whether the module files should be imported individually. During the module build, all module code is compiled into few files, which are imported instead by default. Loading the compiled versions is faster, using the individual files is easier for debugging and testing out adjustments."

$params = @{
    Module      = 'dbarefresh'
    Name        = 'Config.NotSupportedDataTypes'
    Value       = @('geography', 'geometry')
    Description = 'Supported data types used in several command to filter out columns'
}
Set-PSFConfig @params

$params = @{
    Module      = 'dbarefresh'
    Name        = 'Config.SupportedOperators'
    Value       = @('eq', '=', 'in', 'le', '<=', 'lt', '<', 'ge', '>=', 'gt', '>', 'like')
    Description = 'Supported operators used to tests the JSON file'
}
Set-PSFConfig @params
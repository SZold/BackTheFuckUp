Param (
    [switch]$InvokedFromURL = $false,
    [string]$backupperscript = "",
    [switch]$Verbose = $false
)

#include scripts
. ($PSScriptRoot+'\scripts\LogBook.ps1')
. ($PSScriptRoot+'\scripts\helpers.ps1')
. ($PSScriptRoot+'\scripts\BackUpper.ps1')
#end include scripts

Enum BackTheFuckUpActivationType
{  
    DryRun
    CheckOutBeforeBackUp
    BackUp
}

doLog -entry "-------------------------------------------------------------------------------------"
doLog -entry "Start Backupping" -type ChapterStart
doLog -entry ("Verbose: "+$Verbose) -Type Detail
doLog -entry ("InvokedFromURL: "+$InvokedFromURL) -Type Detail
doLog -entry ("backupperscript: ("+$backupperscript+")") -Type Detail

if (-not(Get-Module -Name BurntToast -ListAvailable)) {
    Install-Module -Name BurntToast -Force
}
doLog -entry "Back Up proccess finished!" -Type ChapterEnd
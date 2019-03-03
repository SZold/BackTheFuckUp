Param (
    [switch]$InvokedFromURL = $false,
    [string]$backupperscript = ""
)

Enum BackTheFuckUpActivationType
{  
    DryRun
    CheckOutBeforeBackUp
    BackUp
}

$Action = [System.Management.Automation.ActionPreference]::SilentlyContinue;
$DebugPreference = $VerbosePreference = $WarningPreference = $ErrorActionPreference = $InformationPreference = $Action;

#include scripts
. ($PSScriptRoot+'\scripts\LogBook.ps1')
. ($PSScriptRoot+'\scripts\Functions.ps1')
. ($PSScriptRoot+'\scripts\helpers.ps1')
. ($PSScriptRoot+'\scripts\BackUpper.ps1')
#end include scripts    

Try {
    loadConfigs($PSScriptRoot+"\config.xml");
    
    $Action = $script:ConfigXML.config.ActionPreference;
    $DebugPreference = $VerbosePreference = $WarningPreference = $ErrorActionPreference = $InformationPreference = $Action;

    OpenLogBook;
    doLog -entry "Start Backupping" -type ChapterStart
    doLog -entry ("InvokedFromURL: "+$InvokedFromURL) -Type Detail
    doLog -entry ("backupperscript: ("+$backupperscript+")") -Type Detail
    
    loadDependecies;    
    CreateRegistryEntriesAndShortcuts;
    
    
    doLog -entry "Start Jobs" -type ChapterStart

    $Jobs = startJobs
    
    doLog -entry "Wait Jobs" -type Important

    waitJobs -Jobs $Jobs

    doLog -entry "Receive Jobs" -type Important
     

    doLog -entry "Finished Jobs" -type ChapterEnd


    doLog -entry "Back Up proccess finished!" -Type ChapterEnd

} Catch  {
    if ($script:LogBook -eq $null) { 
        write-error ("Unhandled exception occured: "+$_)  
    }else{       
        doLog -entry ("Unhandled exception occured: ") -Type Error   
        doLog -entry ("'"+$_+"'") -Type Exception   
    }  
} Finally {
    CloseLogBook; 
}

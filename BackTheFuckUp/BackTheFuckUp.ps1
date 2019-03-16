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
    $script:ProcessId = $pid
    loadConfigs($PSScriptRoot+"\config.xml");
    
    $Action = $script:ConfigXML.config.ActionPreference;
    $DebugPreference = $VerbosePreference = $WarningPreference = $ErrorActionPreference = $InformationPreference = $Action;

    OpenLogBook;
    doLog -entry (cutpad -string "Start BackTheFuckUpper" -num 150) -type ChapterStart
    doLog -entry ("ProcessId: "+$script:ProcessId) -Type Detail
    doLog -entry "Start Configurations" -type ChapterStart
    doLog -entry ("InvokedFromURL: "+$InvokedFromURL) -Type Detail
    doLog -entry ("backupperscript: ("+$backupperscript+")") -Type Detail
    
    loadDependecies;    
    CreateRegistryEntriesAndShortcuts;    
    
    doLog -entry "Finished Configurations" -type ChapterEnd
    
    doLog -entry "Get backing up informations" -type ChapterStart
    $BackUpConfigs = (getBackUpConfigs -BackUps $script:configXML.Backups)
    doLog -entry "Got backing up informations" -type ChapterEnd
        
    doLog -entry "Start Jobs" -type ChapterStart
    $Jobs = startJobs -BackUpConfigs $BackUpConfigs
    doLog -entry "Started Jobs" -type ChapterEnd
    
    doLog -entry "Wait Jobs" -type ChapterStart
    waitJobs -Jobs $Jobs
    doLog -entry "Waited Jobs" -type ChapterEnd

    doLog -entry "Receive Jobs" -type Important

    doLog -entry (cutpad -string "BackTheFuckUpper finished!" -num 150) -Type ChapterEnd

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

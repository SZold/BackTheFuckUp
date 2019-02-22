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

#include scripts
. ($PSScriptRoot+'\scripts\LogBook.ps1')
. ($PSScriptRoot+'\scripts\BackTheFuckUp_Functions.ps1')
. ($PSScriptRoot+'\scripts\helpers.ps1')
. ($PSScriptRoot+'\scripts\BackUpper.ps1')
#end include scripts


Try {
    loadConfigs($PSScriptRoot+"\config.xml");

    OpenLogBook;
    doLog -entry "Start Backupping" -type ChapterStart
    doLog -entry ("InvokedFromURL: "+$InvokedFromURL) -Type Detail
    doLog -entry ("backupperscript: ("+$backupperscript+")") -Type Detail
    
    loadDependecies;    
    CreateRegistryEntriesAndShortcuts;


    doLog -entry "Back Up proccess finished!" -Type ChapterEnd
} Catch  {
    if ($script:LogBook -eq $null) { 
        write-error ("UNHANDLED_ERROR_OCCURED:: "+$_)  
    }else{       
        doLog -entry ("{%UNHANDLED_ERROR_OCCURED%}") -Type Error   
        doLog -entry ("'"+$_+"'") -Type Exception   
    }  
} Finally {
    CloseLogBook; 
}

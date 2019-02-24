Param (
    [string]$JobId = "",
    [string]$ScriptRoot = $null,
    [string]$sleep = 1
)

$Action = [System.Management.Automation.ActionPreference]::Continue;
$DebugPreference = $VerbosePreference = $WarningPreference = $ErrorActionPreference = $InformationPreference = $Action;

if($JobId.Length -eq 0){$JobId = [guid]::NewGuid().Guid}
if($null -eq $ScriptRoot){$ScriptRoot =$PSScriptRoot}

function configLogBook(){
    [LogBook]$script:LogBook = [LogBook]::new(); 
    $script:LogBook.config.OutputConfigs += [LogBookOutputConfig]::new([LogBookOutput]::File, [LogBookLevel]::Level1, "", "\..\log\jobs\Error_job_"+$JobId+"_{_FILENAMEDATETIME_}.log", "yyyy-MM-dd");
    #$script:LogBook.config.OutputConfigs += [LogBookOutputConfig]::new([LogBookOutput]::File, [LogBookLevel]::Level6, "", "\..\log\jobs\Log_job_"+$JobId+"_{_FILENAMEDATETIME_}.log", "yyyy-MM-dd");
    $script:LogBook.config.OutputConfigs += [LogBookOutputConfig]::new([LogBookOutput]::ScriptOutput, [LogBookLevel]::Level6, "{_ENTRY_}");
    doLog -entry ("OutputConfigs: ("+$script:LogBook.config.OutputConfigs.Count+")") -type Debug;
}

function doLog{
    Param(
      [string]$entry,
      [string]$Type = "Log"
    )
    
    if ($script:LogBook -eq $null) {
        Write-Output ("["+[System.DateTime]::Now.ToString("MM-dd-yyyy HH:mm:ss.fff")+"]["+$Type+"]  "+$entry)
    }else{    
        $script:LogBook.doLog($entry, $Type);
    }
}

#include scripts
$logbookPath = $ScriptRoot+'\scripts\LogBook.ps1';
if(Test-Path ($logbookPath)){
    . ($logbookPath)
    configLogBook;
}else{
    doLog -entry ("LogBook was not found @ ("+$logbookPath+")") -type Error;
}
#end include scripts

Try {
    doLog -entry ("Starting Job: ("+$JobId+")") -type ChapterStart;
    doLog -entry ("args("+$args[0]+"|"+$args[1]+"|"+$args[2]+")") -type Detail;

    #Write-Progress -Activity "Running job" -Status 1 -PercentComplete 0 -CurrentOperation "Current: Starting";
    sleep($sleep)
    doLog -entry ("sajt1") -type Important;
    #Write-Progress -Activity "Running job2" -Status 2 -PercentComplete 50 -CurrentOperation "Current: Running";
    sleep($sleep)
    #Write-Progress -Activity "Running job3" -Status 3 -PercentComplete 100 -CurrentOperation "Current: Finished";

    doLog -entry ("sajt2") -type Log;
    sleep($sleep)
    doLog -entry ("sajt3") -type FullDetail;
    sleep($sleep)
    
    #Write-Progress "Current: Finished";
} Catch  {
    if ($script:LogBook -eq $null) { 
        write-error ("Unhandled exception occured: ")  
        write-error ($_)  
    }else{       
        doLog -entry ("Unhandled exception occured: ") -Type Error   
        doLog -entry ("'"+$_+"'") -Type Exception   
    }  
} Finally {
    doLog -entry ("Finishing Job: ("+$JobId+")") -type ChapterEnd;
    if ($script:LogBook -ne $null) {
        #$script:LogBook.LogBook_Result | foreach {Write-Output $_.ToString() } ;
    }
}

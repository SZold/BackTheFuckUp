Param (
    [string]$JobId = "",
    [string]$ScriptRoot = $null,
    [string]$BackUpConfig = $null
)
$script:ProcessId = $pid
$sleep = 1

$Action = [System.Management.Automation.ActionPreference]::SilentlyContinue;
$DebugPreference = $VerbosePreference = $WarningPreference = $ErrorActionPreference = $InformationPreference = $Action;

if($JobId.Length -eq 0){$JobId = [guid]::NewGuid().Guid}
if($null -eq $ScriptRoot){$ScriptRoot =$PSScriptRoot}

function configLogBook(){
    [LogBook]$script:LogBook = [LogBook]::new(); 
    $script:LogBook.config.OutputConfigs += [LogBookOutputConfig]::new([LogBookOutput]::File, [LogBookLevel]::Level1, "", "\..\log\jobs\Error_job_"+$JobId+"_{_FILENAMEDATETIME_}.log", "yyyy-MM-dd");
    $script:LogBook.config.OutputConfigs += [LogBookOutputConfig]::new([LogBookOutput]::File, [LogBookLevel]::Level4, "", "\..\log\jobs\Log_job_"+$JobId+"_{_FILENAMEDATETIME_}.log", "yyyy-MM-dd");
    $script:LogBook.config.OutputConfigs += [LogBookOutputConfig]::new([LogBookOutput]::ScriptOutput, [LogBookLevel]::Level4, "{_ENTRY_}");
    $script:LogBook.config.OutputConfigs += [LogBookOutputConfig]::new([LogBookOutput]::Console, [LogBookLevel]::Level4, "");
    
    doLog -entry ("OutputConfigs: ("+$script:LogBook.config.OutputConfigs.Count+")") -type Debug;
}

function doLog{
    Param(
      [string]$entry,
      [string]$Type = "Log"
    )
    
    if ($script:LogBook -eq $null) {
        $log = "["+[System.DateTime]::Now.ToString("MM-dd-yyyy HH:mm:ss.fff")+"]["+$Type+"]  "+$entry
        Write-Output ($log)

        $filepath = $PSScriptRoot+"\BackUpJob_log.txt"
        if (!(Test-Path $filepath)){
           New-Item $filepath -type "file" -Force | Out-Null
        }
        $log | Out-File $filepath -Force -Append;
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

. ($ScriptRoot+'\scripts\BackUpper.ps1');
#end include scripts

Try {
    doLog -entry ("Starting Job: ("+$JobId+") ("+$script:ProcessId+")") -type ChapterStart;
    
    if($BackUpConfig.Length -gt 0){
        $DesBackUpConfig =  [System.Management.Automation.PSSerializer]::Deserialize($BackUpConfig) ;
        doLog -entry ("BackUpConfig("+$DesBackUpConfig.id+")") -type log;
        
        doLog -entry ("DesBackUpConfig.Source("+$DesBackUpConfig.Source+")") -type Detail;
        
        foreach($TargetPath in $DesBackUpConfig.Target.path ){  
            doLog -entry ("DesBackUpConfig.TargetPath("+$TargetPath+")") -type Detail;
        }
        [BackUpper]$BackUpper = [BackUpper]::new($DesBackUpConfig.Source, $TargetPath);
    }else{
        doLog -entry ("BackUpConfig() is null") -type error;
        [BackUpper]$BackUpper = [BackUpper]::new("E:\temp", "C:\temp");
        $FilterXML = "<Whitelist><Extensions><Extension>.txt</Extension></Extensions></Whitelist>
		              <BlackList><Paths><Path>\temp\</Path></Paths></BlackList>";
    }
    
    doLog -entry ("BackUpper.doBackUp(true)") -type log;
    $results = $BackUpper.doBackUp($null, $true);
    doLog -entry ("BackUpper.doBackUp(true)") -type Success;


    
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
    doLog -entry ("Job Finished ("+$JobId+")") -type ChapterEnd;
    if ($script:LogBook -ne $null) {
        #$script:LogBook.LogBook_Result | foreach {Write-Output $_.ToString() } ;
    }
}

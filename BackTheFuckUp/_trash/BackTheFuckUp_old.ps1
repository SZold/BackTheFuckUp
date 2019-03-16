Param (
    [switch]$InvokedFromURL = $false,
    [string]$backupperscript = "",
    [switch]$Verbose = $false
)

#Start stopwatch to measure how much time the the back up takes (each separate script file should do this to see a detailed time)
$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

#include scripts
. ($PSScriptRoot+'\LogBook.ps1')
. ($PSScriptRoot+'\helpers.ps1')
. ($PSScriptRoot+'\BackUpper.ps1')
#end include scripts

Enum BackTheFuckUpActivationType
{  
    DryRun
    CheckOutBeforeBackUp
    BackUp
}

if(($backupperscript -eq [BackTheFuckUpActivationType]::DryRun) -Or 
   ($backupperscript -eq [BackTheFuckUpActivationType]::BackUp) ){
    #The console should be hidden
}elseif($backupperscript -eq [BackTheFuckUpActivationType]::CheckOutBeforeBackUp){
    #The console should be shown
}else{
    #Should be during development
    $Verbose = $true
}

doLog -entry "-------------------------------------------------------------------------------------"
doLog -entry "Start Backupping" -type ChapterStart
doLog -entry ("Verbose: "+$Verbose) -Type Detail
doLog -entry ("InvokedFromURL: "+$InvokedFromURL) -Type Detail
doLog -entry ("backupperscript: ("+$backupperscript+")") -Type Detail

if (-not(Get-Module -Name BurntToast -ListAvailable)) {
    Install-Module -Name BurntToast -Force
}

$TargetPath = 'wscript.exe'
$Parameters = ('"'+$PSScriptRoot+'\runhidden.vbs" "-InvokedFromURL -%1"');
$ProceedAction = ($TargetPath + ' ' + $Parameters);

AddRegistryEntries -protocolName:'backupperscript' -ProceedAction:($ProceedAction);
CreateShortcut -shortcutFilePath:($PSScriptRoot+"\Shortcut_BackUp.lnk") -TargetPath:($TargetPath) -Parameters:($Parameters.Replace("%1", "backupperscript:BackUp")) 
CreateShortcut -shortcutFilePath:($PSScriptRoot+"\Shortcut_DryRun.lnk") -TargetPath:($TargetPath) -Parameters:($Parameters.Replace("%1", "backupperscript:DryRun")) 
$command = "Get-ChildItem '$PSScriptRoot\log\*.log' | sort LastWriteTime | select -last 1 | Get-Content -Wait "
CreateShortcut -shortcutFilePath:($PSScriptRoot+"\Shortcut_ViewLastLog.lnk") -TargetPath:("powershell") -Parameters:(" -nologo -command `"&{$command}`"" ) 

[BackUpper]$sajt = [BackUpper]::new("E:\temp\source", "E:\temp\target");
#[BackUpper]$sajt = [BackUpper]::new("E:\", "C:\temp\target");
$sajt.WhiteListedExtensions = @(".txt", ".doc", ".mp3", ".iso");

doLog -entry ("ProceedAction: ("+$ProceedAction+")") -Type Detail 

if($backupperscript -eq [BackTheFuckUpActivationType]::BackUp){
    doLog -entry ("Do Back Up") -Type Important
    $ProgressBar = New-BTProgressBar -Status ('{%BACKING_UP_FILE%}') -Indeterminate 
    New-BurntToastNotification –Text (‘{%BACKING_UP_PATH%}’) -ProgressBar $ProgressBar –UniqueIdentifier 'sajt001' 
    $sajt.doBackUp();
    sleep(5)
    New-BurntToastNotification –Text (‘{%BACKING_UP_DONE%}’)  –UniqueIdentifier 'sajt001' 
}elseif($backupperscript -eq [BackTheFuckUpActivationType]::CheckOutBeforeBackUp){
    doLog -entry ("Do Check Out") -Type Important
    $sajt.doBackUp();
}else{
    doLog -entry ("Do Dry Run") -Type Important
    $results = $sajt.doBackUp($true);
       
    $deleteSize = $results[[BackUpperActionType]::DeleteFromTarget].FileSizeDelta;
    $deleteSizeFriendly = GetFriendlySize($deleteSize);
    $copySize = $results[[BackUpperActionType]::SaveToTarget].FileSizeSum + $results[[BackUpperActionType]::SaveNewVersionToTarget].FileSizeSum;
    $copySizeFriendly = GetFriendlySize($copySize);
    $deltaSize = $results[[BackUpperActionType]::SaveToTarget].FileSizeDelta + $results[[BackUpperActionType]::SaveNewVersionToTarget].FileSizeDelta+$results[[BackUpperActionType]::DeleteFromTarget].FileSizeDelta;
    $deltaSizeFriendly = GetFriendlySize($deltaSize);
    $freeTargetSpace = ((Get-Item $sajt.TargetPath).PSDrive | Select-Object Free).Free;
    $freeTargetSpaceFriendly = GetFriendlySize($freeTargetSpace)

    doLog -entry ("Got sizes (Delete: "+$results[[BackUpperActionType]::DeleteFromTarget].FileSizeSum +" | " +
                                      "Δ"+$results[[BackUpperActionType]::DeleteFromTarget].FileSizeDelta +" || " +
                               "Save: "  +$results[[BackUpperActionType]::SaveToTarget].FileSizeSum +" | " +
                                      "Δ"+$results[[BackUpperActionType]::SaveToTarget].FileSizeDelta +" || " +
                              "SaveNew: "+$results[[BackUpperActionType]::SaveNewVersionToTarget].FileSizeSum +" | " +
                                      "Δ"+$results[[BackUpperActionType]::SaveNewVersionToTarget].FileSizeDelta +" || " +
                                  "Free:"+$freeTargetSpace +" | "+
                                      "Δ"+($freeTargetSpace - $deltaSize ) +")") -Type FullDetail

    $line1 = ‘{%BACKUP_COUNT%}: ’+ ($results[[BackUpperActionType]::SaveToTarget].FileCount + $results[[BackUpperActionType]::SaveNewVersionToTarget].FileCount)+' {%BACKUP_FILES%}';
    $line2 =  ‘{%BACKUP_SIZE%}: '+ $deltaSizeFriendly ;
    $line3 = ‘{%FREE_SPACE_LEFT%}: ’+$freeTargetSpaceFriendly ;    
    doLog -entry ("Got Notification texts")    
    LogBook_TabIn;
    doLog -entry ("line1: $line1") -type Detail     
    doLog -entry ("line2: $line2") -type Detail     
    doLog -entry ("line3: $line3") -type Detail  
    LogBook_TabOut;      
    
    if($deltaSize -gt $freeTargetSpace){
        doLog -entry ("deltaSize > freeTargetSpace | $deltaSize > $freeTargetSpace | "+($deltaSize -gt $freeTargetSpace)) -Type Important
        $BTHeader = New-BTHeader -Title '{%NOT_ENOUGH_FREE_SPACE%}' -Id 1 
        $BTButton_Proceed = New-BTButton -Content '{%SEE_STORAGE%}' -Arguments ("ms-settings:storagesense") -ActivationType Protocol
    }else{
        $BTHeader = New-BTHeader -Title '{%NOTIFICATION_TITLE%}' -Id 1 
        $BTButton_Proceed = New-BTButton -Content '{%PROCEED%}' -Arguments ("backupperscript:"+[BackTheFuckUpActivationType]::BackUp) -ActivationType Protocol
    }
    $BTButton_Check = New-BTButton -Content '{%CHECK%}' -Arguments("backupperscript:"+[BackTheFuckUpActivationType]::CheckOutBeforeBackUp) -ActivationType Protocol
    $BTButton_Fuckoff = New-BTButton -Content '{%FUCK_OFF%}' -Dismiss
    
    doLog -entry ("Send Toast Notification")    
    New-BurntToastNotification -Header $BTHeader -Button $BTButton_Proceed, $BTButton_Fuckoff  –Text ($line1), 
                                                                                                     ($line2), 
                                                                                                     ($line3)
}
#Write out the time ellapsed from the start of the build
doLog -entry "Back Up proccess finished!" -Type ChapterEnd



    <#
    $Output = $Job.Debug.ReadAll(); 
    doLogJobOutput -JobName ($Job | Get-Job).Name -Output $Output -LogType ([LogBookType]::Debug);  
    $Job.Debug.Clear();
    
    $Output = $Job.Verbose.ReadAll(); 
    doLogJobOutput -JobName ($Job | Get-Job).Name -Output $Output -LogType ([LogBookType]::Fulldetail);  
    $Job.Verbose.Clear();
    
    $Output = $Job.Warning.ReadAll();
    doLogJobOutput -JobName ($Job | Get-Job).Name -Output $Output -LogType ([LogBookType]::Important);  
    $Job.Warning.Clear();
    
    $Output = $Job.Error.ReadAll();
    doLogJobOutput -JobName ($Job | Get-Job).Name -Output $Output -LogType ([LogBookType]::Error);  
    $Job.Error.Clear();    
    
    $Output = $Job.Output.ReadAll();
    doLogJobOutput -JobName ($Job | Get-Job).Name -Output $Output -LogType ([LogBookType]::log);  
    $Job.Output.Clear();
    
    $Output = $Job.Progress.ReadAll();
    #doLogJobOutput -JobName ($Job | Get-Job).Name -Output $Output[0] -LogType ([LogBookType]::Success);  
    $Job.Progress.Clear();#>

    
<#


                $Prog = ($Job | Get-Job).ChildJobs[0].Progress.StatusDescription[-1]
                If ($Prog -is [char]){
                   $Prog = 0
                }
                $TotProg += $Prog
                #doLog -entry ("Receive Jobs ("+($Job | Get-Job).Name+"): Prog = '$Prog': Output = '$Output'") -type fulldetail
#>
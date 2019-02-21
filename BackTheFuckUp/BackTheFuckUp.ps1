﻿Param (
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
CreateShortcuts -shortCutPath:($PSScriptRoot) -TargetPath:($TargetPath) -Parameters:($Parameters) 

[BackUpper]$sajt = [BackUpper]::new("E:\temp\source", "E:\temp\target");
#[BackUpper]$sajt = [BackUpper]::new("E:\", "C:\temp\target");
$sajt.WhiteListedExtensions = @(".txt", ".doc", ".mp3", ".iso");

doLog -entry ("ProceedAction: ("+$ProceedAction+")") -Type Detail 

if($backupperscript -eq [BackTheFuckUpActivationType]::BackUp){
    doLog -entry ("Do Back Up") -Type Important
    $ProgressBar = New-BTProgressBar -Status ('Backing up "'+$this.SourcePath+'"') -Indeterminate 
    New-BurntToastNotification –Text (‘Backing up from "'+$this.SourcePath+'"’) -ProgressBar $ProgressBar –UniqueIdentifier 'sajt001' 
    $sajt.doBackUp();
    sleep(5)
    New-BurntToastNotification –Text (‘Backing up from "'+$this.SourcePath+'" Done’)  –UniqueIdentifier 'sajt001' 
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

    $line1 = ‘Back up: ’+ ($results[[BackUpperActionType]::SaveToTarget].FileCount + $results[[BackUpperActionType]::SaveNewVersionToTarget].FileCount)+' file(s)';
    $line2 =  ‘Size: '+ $deltaSizeFriendly ;
    $line3 = ‘Free space on target: ’+$freeTargetSpaceFriendly ;    
    doLog -entry ("Got Notification texts")    
    LogBook_TabIn;
    doLog -entry ("line1: $line1") -type Detail     
    doLog -entry ("line2: $line2") -type Detail     
    doLog -entry ("line3: $line3") -type Detail  
    LogBook_TabOut;      
    
    if($deltaSize -gt $freeTargetSpace){
        doLog -entry ("deltaSize > freeTargetSpace | $deltaSize > $freeTargetSpace | "+($deltaSize -gt $freeTargetSpace)) -Type Important
        $BTHeader = New-BTHeader -Title 'Not enough free space to Back Up' -Id 1 
        $BTButton_Proceed = New-BTButton -Content 'See Storage' -Arguments ("ms-settings:storagesense") -ActivationType Protocol
    }else{
        $BTHeader = New-BTHeader -Title 'Back The Fuck Up' -Id 1 
        $BTButton_Proceed = New-BTButton -Content 'Proceed' -Arguments ("backupperscript:"+[BackTheFuckUpActivationType]::BackUp) -ActivationType Protocol
    }
    $BTButton_Check = New-BTButton -Content 'Check' -Arguments("backupperscript:"+[BackTheFuckUpActivationType]::CheckOutBeforeBackUp) -ActivationType Protocol
    $BTButton_Fuckoff = New-BTButton -Content 'Fuck off' -Dismiss
    
    doLog -entry ("Send Toast Notification")    
    New-BurntToastNotification -Header $BTHeader -Button $BTButton_Proceed, $BTButton_Fuckoff  –Text ($line1), 
                                                                                                     ($line2), 
                                                                                                     ($line3)
}
#Write out the time ellapsed from the start of the build
doLog -entry "Back Up proccess finished!" -Type ChapterEnd
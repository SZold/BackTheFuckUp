Param (
    [switch]$InvokedFromURL = $false,
    [string]$backupperscript = "",
    [switch]$Verbose = $false
)

$Stopwatch = [System.Diagnostics.Stopwatch]::StartNew();

#Using
. ($PSScriptRoot+'\BackUpper.ps1')
. ($PSScriptRoot+'\helpers.ps1')

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

if($Verbose){
    Write-Host ("StopWatch: "+$Stopwatch.Elapsed.TotalMinutes)
    Write-Host ("Verbose: "+$Verbose)
    Write-Host ("InvokedFromURL: "+$InvokedFromURL)
    Write-Host ("backupperscript: "+$backupperscript)
}

if (-not(Get-Module -Name BurntToast -ListAvailable)) {
    Install-Module -Name BurntToast -Force
}

$TargetPath = 'wscript.exe'
$Parameters = ('"'+$PSScriptRoot+'\runhidden.vbs" "-InvokedFromURL -%1"');
$ProceedAction = ($TargetPath + ' ' + $Parameters);

CreateShortcuts -shortCutPath:($PSScriptRoot) -TargetPath:($TargetPath) -Parameters:($Parameters) 
AddRegistryEntries -protocolName:'backupperscript' -ProceedAction:($ProceedAction);

[BackUpper]$sajt = [BackUpper]::new("E:\temp\source", "E:\temp\target");
#[BackUpper]$sajt = [BackUpper]::new("E:\", "D:\");
$sajt.WhiteListedExtensions = @(".txt", ".exe", ".avi", ".doc", ".mp3");

if($Verbose){
    #$results | Sort-Object -Property actionType | Format-Table
    Write-Host $ProceedAction 
}

if($backupperscript -eq [BackTheFuckUpActivationType]::BackUp){
    $ProgressBar = New-BTProgressBar -Status ('Backing up "'+$this.SourcePath+'"') -Indeterminate
    New-BurntToastNotification –Text (‘Backing up from "'+$this.SourcePath+'"’) -ProgressBar $ProgressBar –UniqueIdentifier 'sajt001' 
    $sajt.doBackUp();
    sleep(5)
    New-BurntToastNotification –Text (‘Backing up from "'+$this.SourcePath+'" Done’)  –UniqueIdentifier 'sajt001' 
}elseif($backupperscript -eq [BackTheFuckUpActivationType]::CheckOutBeforeBackUp){
    $sajt.doBackUp();
}else{
    $results = $sajt.doBackUp($true);
    
    $deleteSize = GetFriendlySize($results[[BackUpperActionType]::DeleteFromTarget].FileSizeDelta);
    $backingUpSize = GetFriendlySize($results[[BackUpperActionType]::SaveToTarget].FileSizeDelta + $results[[BackUpperActionType]::SaveNewVersionToTarget].FileSizeDelta);
    $copySize = GetFriendlySize($results[[BackUpperActionType]::SaveToTarget].FileSizeSum + $results[[BackUpperActionType]::SaveNewVersionToTarget].FileSizeSum);

    $backingUp = ‘Back up: ’+ ($results[[BackUpperActionType]::SaveToTarget].FileCount + $results[[BackUpperActionType]::SaveNewVersionToTarget].FileCount)+' ('+ $backingUpSize +')';
    $deleting =  ‘Delete: ’+ ($results[[BackUpperActionType]::DeleteFromTarget].FileCount)+' ('+ $deleteSize +')';
    $copy = ‘Copy size: ’+ ($results[[BackUpperActionType]::Nothing].FileCount);

    $BTHeader = New-BTHeader -Title 'Back The Fuck Up' -Id 1
    $BTButton_Proceed = New-BTButton -Content 'Proceed' -Arguments ("backupperscript:"+[BackTheFuckUpActivationType]::BackUp) -ActivationType Protocol
    $BTButton_Check = New-BTButton -Content 'Check' -Arguments("backupperscript:"+[BackTheFuckUpActivationType]::CheckOutBeforeBackUp) -ActivationType Protocol
    $BTButton_Fuckoff = New-BTButton -Content 'Fuck off' -Dismiss
    New-BurntToastNotification -Header $BTHeader -Button $BTButton_Proceed, $BTButton_Fuckoff  –Text ($backingUp), 
                                                                                                     ($deleting), 
                                                                                                     ($copy)
}
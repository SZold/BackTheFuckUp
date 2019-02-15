Param (
    [switch]$InvokedFromURL = $false,
    [string]$backupperscript = "",
    [switch]$Verbose = $false
)

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

}elseif($backupperscript -eq [BackTheFuckUpActivationType]::CheckOutBeforeBackUp){

}else{
    #Should be during development
    $Verbose = $true
}

if($Verbose){
    Write-Host ("Verbose: "+$Verbose)
    Write-Host ("InvokedFromURL: "+$InvokedFromURL)
    Write-Host ("backupperscript: "+$backupperscript)
}

if (-not(Get-Module -Name BurntToast -ListAvailable)) {
    Install-Module -Name BurntToast -Force
}

$runMe = $PSScriptRoot+'\'+$MyInvocation.MyCommand.Name 
#AddRegistryEntries -protocolName:'backupperscript'       -ProceedAction:('powershell.exe -ExecutionPolicy Bypass -File "'+$runMe+'" -InvokedFromURL -%1');
AddRegistryEntries -protocolName:'backupperscript'       -ProceedAction:($PSScriptRoot+'\runhidden.vbs "-InvokedFromURL -%1"');


[BackUpper]$sajt = [BackUpper]::new("E:\Letöltések", "E:\temp\target");
$sajt.WhiteListedExtensions = @(".txt");
$results = $sajt.doDryRun();

if($Verbose){
    $results | Sort-Object -Property actionType | Format-Table
    Write-Host $ProceedAction 
}

if($backupperscript -eq [BackTheFuckUpActivationType]::BackUp){
    
    $sajt.doBackUp($results);
}elseif($backupperscript -eq [BackTheFuckUpActivationType]::CheckOutBeforeBackUp){
    $results | Sort-Object -Property actionType | Format-Table
    $pass = Read-Host 'Should proceed with the back up? ' -AsSecureString
    $sajt.doBackUp($results);
}else{
    $Nothing = ($results | Where {$_.actionType -eq [BackUpperActionType]::Nothing} | measure).Count
    $SaveToTarget = ($results | Where {$_.actionType -eq [BackUpperActionType]::SaveToTarget} | measure).Count
    $DeleteFromTarget = ($results | Where {$_.actionType -eq [BackUpperActionType]::DeleteFromTarget} | measure).Count
    $SaveNewVersionToTarget = ($results | Where {$_.actionType -eq [BackUpperActionType]::SaveNewVersionToTarget} | measure).Count

    $BTHeader = New-BTHeader -Title 'Back The Fuck Up' -Id 1
    #$BTButton_Proceed = New-BTButton -Content 'Proceed' -Arguments ($protocoName +":") -ActivationType Protocol
    $BTButton_Proceed = New-BTButton -Content 'Proceed' -Arguments ("backupperscript:"+[BackTheFuckUpActivationType]::BackUp) -ActivationType Protocol
    $BTButton_Check = New-BTButton -Content 'Check' -Arguments("backupperscript:"+[BackTheFuckUpActivationType]::CheckOutBeforeBackUp) -ActivationType Protocol
    $BTButton_Fuckoff = New-BTButton -Content 'Fuck off' -Dismiss
    New-BurntToastNotification -Header $BTHeader -Button $BTButton_Proceed, $BTButton_Check, $BTButton_Fuckoff  –Text (‘Back up Files: ’+($SaveToTarget+$SaveNewVersionToTarget)), 
                                                                                                     (‘Delete from backed up files: ’+$DeleteFromTarget), 
                                                                                                     (‘Do nothing about: ’+$Nothing)

}
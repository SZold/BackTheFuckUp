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
    $Jobs = @()
    $Total = 2
    $LogString =""; 
    for($i = 1; $i -le $Total; $i++){
        $Jobs += Start-Job -FilePath ($PSScriptRoot+"\scripts\BackUpJob.ps1") -ArgumentList ("test"+(10+$i)), $PSScriptRoot, ($i*2) -Name ("test"+(10+$i))
        doLog -entry ("Job '"+("test"+$i)+"' started") -type detail
        $LogStringTmp = "|"+(10+$Count)+":"+(Get-Job -Name ("test"+(10+$i))).State  
        $LogStringTmp = $LogStringTmp.subString(0, [System.Math]::Min(15, $LogStringTmp.Length)).PadRight(15, " ") ;   
        $LogString += $LogStringTmp
    }
    $LogString = ([char]0x25DC)+$LogString.subString(0, [System.Math]::Min(10, $LogString.Length)).PadRight(10, " ") ;  
    
    Write-Progress -Activity  "Check Jobs" -Status $LogString
    doLog -entry "Wait Jobs" -type Important
    
    $TotProg = 0
    $Comp = 0

    Do {    
        $TotProg++
        $Count = 0
        $LogString =""; 
        ForEach ($Job in $Jobs){
            $Count++;
            Try {
                $LogStringTmp = "|"+(10+$Count)+":"+($Job | Get-Job).State  
                $LogStringTmp = $LogStringTmp.subString(0, [System.Math]::Min(15, $LogStringTmp.Length)).PadRight(15, " ") ;   
                $LogString += $LogStringTmp
                doLogJob(($Job | Get-Job).ChildJobs[0]);
            }Catch {
                Start-Sleep -Milliseconds 1
                Break
            }
        }
        if(0 -eq ($TotProg % 4)){
            $TotProg = 0
        }
        if($TotProg -eq 0){$LogString = ("| ")+$LogString;  }
        if($TotProg -eq 1){$LogString = ("/ ")+$LogString;  }
        if($TotProg -eq 2){$LogString = ("- ")+$LogString;  }
        if($TotProg -eq 3){$LogString = ("\ ")+$LogString;  }
        # | / - \ 
        #doLog -entry $LogString -type debug         
        Write-Progress -Activity "Check Jobs" -Status $LogString -PercentComplete ((($Jobs | Where State -eq "Completed").Count / $Total)*100)
       # Write-Progress -Id 1 -Activity "Watching Background Jobs" -Status "Waiting for background jobs to complete: $TotProg of $Total"  -PercentComplete (($TotProg / $Total) * 100)
        Start-Sleep -Milliseconds 100
        
    } Until (($Jobs | Where State -eq "Running").Count -eq 0)    
        ForEach ($Job in $Jobs){
        doLogJob(($Job | Get-Job).ChildJobs[0]);
    }

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

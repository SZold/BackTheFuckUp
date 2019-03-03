﻿
function loadDependecies(){
    doLog -entry ("Load Dependecies") -Type Detail  
    LogBook_TabIn;
    if (-not(Get-Module -Name BurntToast -ListAvailable))
    {        
        if(checkAdminRights){
            doLog -entry ("Load BurntToast module") -Type Detail  
            LogBook_TabIn;
            try { 
                $result = Install-Module -Name BurntToast -Force -ErrorAction Stop
                doLog -entry ("Loaded BurntToast module!") -Type Success   
            } catch {        
                doLog -entry ("Error during loading BurntToast module: '"+$_+"'") -Type Exception        
            }
            LogBook_TabOut;
        }
    }
    LogBook_TabOut;
}

function CreateRegistryEntriesAndShortcuts(){
    doLog -entry ("CreateRegistryEntriesAndShortcuts") -Type Detail  
    LogBook_TabIn;
     try { 
        $protocolName = $script:configXML.Configs.BackTheFuckUpProtocolName;
        $TargetPath = $script:configXML.Configs.VBScriptExecutable;
        $Parameters = ('"'+$PSScriptRoot+'\runhidden.vbs" "-InvokedFromURL -%1"');
        $ProceedAction = ($TargetPath + ' ' + $Parameters);
        doLog -entry ("ProceedAction: ("+$ProceedAction+")") -Type Detail 

        AddAllRegistryEntries -protocolName:$protocolName -ProceedAction:($ProceedAction);
        CreateShortcut -shortcutFilePath:($PSScriptRoot+"\..\bin\Shortcut_BackUp.lnk") -TargetPath:($TargetPath) -Parameters:($Parameters.Replace("%1", "backupperscript:BackUp")) 
        CreateShortcut -shortcutFilePath:($PSScriptRoot+"\..\bin\Shortcut_DryRun.lnk") -TargetPath:($TargetPath) -Parameters:($Parameters.Replace("%1", "backupperscript:DryRun")) 
        $command = "Get-ChildItem '$PSScriptRoot\log\*.log' | sort LastWriteTime | select -last 1 | Get-Content -Wait "
        CreateShortcut -shortcutFilePath:($PSScriptRoot+"\..\bin\Shortcut_ViewLastLog.lnk") -TargetPath:($script:configXML.Configs.PowershellExecutable) -Parameters:(" -nologo -command `"&{$command}`"" ) 
    } catch {        
        doLog -entry ("Error during CreateRegistryEntriesAndShortcuts: '"+$_+"'") -Type Exception        
    }  
    LogBook_TabOut;
}


function AddAllRegistryEntries($protocolName, $ProceedAction){
    doLog -entry ("AddAllRegistryEntries") -Type Detail  
    LogBook_TabIn;
    foreach( $RegistryEntry in $script:configXML.Configs.RegistryEntries.RegistryEntry ){  
        $key = $RegistryEntry.key.replace("{_BACKTHEFUCKUP_PROTOCOL_}", $protocolName)
        $name = $RegistryEntry.name.replace("{_BACKTHEFUCKUP_PROTOCOL_}", $protocolName)
        $value = $RegistryEntry.InnerText.replace("{_BACKTHEFUCKUP_PROTOCOL_}", $protocolName).replace("{_PROCEED_ACTION_}", $ProceedAction)
        $PropertyType = if($RegistryEntry.PropertyType -ne $null){$RegistryEntry.PropertyType}else{"String"};        

        AddRegistryEntry -Key $key -Name $name -Value $value -PropertyType $PropertyType;
    }
    LogBook_TabOut;
}

function writeJobProgress($LogString, $PercentComplete){
    Write-Progress -Activity  "Check Jobs" -Status $LogString -PercentComplete $PercentComplete
}

function startJobs(){
    doLog -entry ("startJobs()") -Type Detail
    $Jobs = @()
    $Total = 2
    $LogString =""; 
    for($i = 1; $i -le $Total; $i++){
        $Jobs += Start-Job -FilePath ($PSScriptRoot+"\BackUpJob.ps1") -ArgumentList ("test"+(10+$i)), $PSScriptRoot, ($i*2) -Name ("test"+(10+$i))
        doLog -entry ("Job '"+("test"+$i)+"' started")
        $LogStringTmp = "|"+(10+$Count)+":started"
        $LogStringTmp = $LogStringTmp.subString(0, [System.Math]::Min(15, $LogStringTmp.Length)).PadRight(15, " ") ;   
        $LogString += $LogStringTmp
    }
    
    writeJobProgress -LogString $LogString -PercentComplete  0
    doLog -entry ("startJobs |"+$Count+" | "+(cutpad -string $percent -num 2)+"% | "+$LogString+" | ") -type Loop

    return $Jobs
}

function waitJobs($Jobs){ 
    doLog -entry ("waitJobs("+$Jobs.Count+")") -Type Detail
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
                doLog -entry ("doLogJob |"+(10+$Count)+"| "+($Job | Get-Job).ChildJobs.Count+" | "+($Job | Get-Job).Information.ReadAll().Count+" | "+$LogStringTmp+" | ") -type Loop
                doLogJob(($Job | Get-Job).ChildJobs[0]);
            }Catch {
                doLog -entry ("Failed to get Job state for: "+($Job | Get-Job).Name) -type FullDetail
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
        $percent =  ((($Jobs | Where State -eq "Completed").Count / $Jobs.Count)*100)
        writeJobProgress -LogString $LogString -PercentComplete $percent
        doLog -entry ("waitJobs |"+$Count+" | "+(cutpad -string $percent -num 2)+"% | "+$LogString+" | ") -type Loop
        # Write-Progress -Id 1 -Activity "Watching Background Jobs" -Status "Waiting for background jobs to complete: $TotProg of $Total"  -PercentComplete (($TotProg / $Total) * 100)


        Start-Sleep -Milliseconds 100
        
    } Until (($Jobs | Where State -eq "Running").Count -eq 0)    
        ForEach ($Job in $Jobs){
        doLogJob(($Job | Get-Job).ChildJobs[0]);
    }
}
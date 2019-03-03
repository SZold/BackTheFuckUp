
function loadDependecies(){
    doLog -entry ("Load Dependecies") -Type Log  
    LogBook_TabIn;
    doInstallModule -name "BurntToast"
    LogBook_TabOut;
}

function doInstallModule($name){
    doLog -entry ("doInstallModule( $name )") -Type FullDetail  
    if (-not(Get-Module -Name $name -ListAvailable))
    {        
        if(checkAdminRights){
            doLog -entry ("Load $name module") -Type Log  
            LogBook_TabIn;
            try { 
                $result = Install-Module -Name $name -Force -ErrorAction Stop
                doLog -entry ("$name module result: "+$result) -Type FullDetail   
                doLog -entry ("Loaded $name module!") -Type Success   
            } catch {        
                doLog -entry ("Error during loading $name module: '"+$_+"'") -Type Exception        
            }
            LogBook_TabOut;
        }
    }else{
        doLog -entry ("Module $name already installed!") -Type Detail  
    }

}

function CreateRegistryEntriesAndShortcuts(){
    doLog -entry ("CreateRegistryEntriesAndShortcuts") -Type Log  
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
        $command = "Get-ChildItem '$PSScriptRoot\..\log\*.log' | sort LastWriteTime | select -last 1 | Get-Content -Wait "
        CreateShortcut -shortcutFilePath:($PSScriptRoot+"\..\bin\Shortcut_ViewLastLog.lnk") -TargetPath:($script:configXML.Configs.PowershellExecutable) -Parameters:(" -nologo -command `"&{$command}`"" ) 
        $command = "Get-ChildItem '$PSScriptRoot\..\log\jobs\*.log' | sort LastWriteTime | select -last 1 | Get-Content -Wait "
        CreateShortcut -shortcutFilePath:($PSScriptRoot+"\..\bin\Shortcut_ViewLastJobLog.lnk") -TargetPath:($script:configXML.Configs.PowershellExecutable) -Parameters:(" -nologo -command `"&{$command}`"" ) 
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

function startJobs($BackUpConfigs){
    doLog -entry ("startJobs(BackUpConfigs= "+$BackUpConfigs.childNodes.Count+")") -Type Detail

    $log = "";
    foreach($childNodes in $BackUpConfigs.childNodes ){  $log += $childNodes.id + " | ";  }
    doLog -entry ("BackUpConfigs.childNodes: "+$log) -type FullDetail 

    
    $Jobs = @();
    $i = 0;
    foreach($BackUpConfig in $BackUpConfigs.childNodes ){ 
        $i++;
        $JobName = $script:configXML.Configs.PowershellJobId.replace("{_JOBID_}",$i);
        $BackUpConfigSerialized =  [System.Management.Automation.PSSerializer]::Serialize($BackUpConfig) ;

        doLog -entry ("Start-Job  -FilePath '"+($PSScriptRoot+"\BackUpJob.ps1")+"'  -Name '$JobName' started") -type Detail
        doLog -entry ("  -ArgumentList '$JobName', '"+$PSScriptRoot+"\..\"+"', '"+($BackUpConfig.length)+"' started") -type FullDetail

        $Jobs += Start-Job -FilePath ($PSScriptRoot+"\BackUpJob.ps1") -ArgumentList ($JobName), ($PSScriptRoot+"\..\"), ($BackUpConfigSerialized) -Name $JobName
        doLog -entry ("Job '$JobName ' started")

        $LogStringTmp = "|$JobName :started"
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
    
    LogBook_TabIn;
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
                doLog -entry ("doLogJob |"+(10+$Count)+"| "+($Job | Get-Job).ChildJobs.Count+" |  | "+$LogStringTmp+" | ") -type loop
                doLogJob(($Job | Get-Job).ChildJobs[0]);
            }Catch {
                doLog -entry ("Failed to get Job state for: "+($Job | Get-Job).Name) -type Error
                doLog -entry ("'"+$_+"'") -Type Error
                LogBook_TabOut;   
                Start-Sleep -Milliseconds 100
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
        LogBook_TabOut;
        doLog -entry ("waitJobs |"+$Count+" | "+(cutpad -string $percent -num 2)+"% | "+$LogString+" | ") -type Loop
        LogBook_TabIn;
        # Write-Progress -Id 1 -Activity "Watching Background Jobs" -Status "Waiting for background jobs to complete: $TotProg of $Total"  -PercentComplete (($TotProg / $Total) * 100)
        Start-Sleep -Milliseconds 100
        
    } Until (($Jobs | Where State -eq "Running").Count -eq 0)        
    doLog -entry ("All jobs completed") -Type Detail
    ForEach ($Job in $Jobs){
        doLogJob(($Job | Get-Job).ChildJobs[0]);
    }
    LogBook_TabOut;
}

function getBackUpConfigs($BackUps){
    [OutputType([System.Xml.XmlElement])]

    [System.Xml.XmlElement]$result = $BackUps.Clone();
    $result.RemoveAll();
    foreach( $BackupConfig in $BackUps.BackUp ){   
        doLog -entry ("Loading BackupConfig: "+ $BackupConfig.id) -type Log
        LogBook_TabIn;
        [System.Xml.XmlElement]$concatConfig = $BackupConfig.Clone();
        
        $log = "";
        foreach($targetpath in $concatConfig.target.path ){  $log += "'"+$targetpath + "'; ";  }
        doLog -entry ("BackupConfig paths: '"+ $concatConfig.Source+"'  => "+ $log+"") -type FullDetail
        
        $concatConfig.AppendChild($BackUps.Whitelist.Clone()) | Out-Null;
        $concatConfig.AppendChild($BackUps.BlackList.Clone()) | Out-Null;
            
        foreach($backupsCompareResult in $BackUps.CompareResults.CompareResult ){
            $CompareResultFound = $false
            foreach($concatCompareResult in $concatConfig.CompareResults.CompareResult ){
                if($backupsCompareResult.InnerText -eq $concatCompareResult.InnerText){
                    doLog -entry ("CompareResults No Override: "+$backupsCompareResult.InnerText) -type FullDetail 
                    $CompareResultFound = $true
                }    
            }
            if(-not $CompareResultFound){         
                    doLog -entry ("CompareResults AppendChild: "+$backupsCompareResult.InnerText) -type FullDetail    
                    $concatConfig.CompareResults.AppendChild($backupsCompareResult.Clone()) | Out-Null;
            }
        }

        doLog -entry ("concatConfig.outerxml: "+$concatConfig.outerxml) -type Loop 
        doLog -entry ("concatConfig.innerxml: "+$concatConfig.innerxml) -type Loop 
        
        $log = "";
        foreach($childNodes in $concatConfig.Whitelist.childNodes ){  $log += $childNodes.Name + " | ";  }
        doLog -entry ("BackupConfig.Whitelist.childNodes: "+$log) -type Detail 
        
        $log = "";
        foreach($childNodes in $concatConfig.BlackList.childNodes ){  $log += $childNodes.Name + " | ";  }
        doLog -entry ("BackupConfig.BlackList.childNodes: "+$log) -type Detail 

        $log = "";
        foreach($childNodes in $concatConfig.CompareResults.childNodes ){  $log += $childNodes.InnerText+"="+$childNodes.ActionType + " | ";  }
        doLog -entry ("BackupConfig.CompareResults.childNodes: "+$log) -type Detail 
        
        LogBook_TabOut;
        $result.AppendChild($concatConfig.Clone()) | Out-Null;
        doLog -entry ("Loaded BackupConfig: "+ $BackupConfig.id) -type Success
    }
    
    $log = "";
    foreach($childNodes in $result.childNodes ){  $log += $childNodes.id + " | ";  }
    doLog -entry ("result.childNodes: "+$log) -type Detail     

    return $result
}
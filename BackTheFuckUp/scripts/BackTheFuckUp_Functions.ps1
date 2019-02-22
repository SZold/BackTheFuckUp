
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
        CreateShortcut -shortcutFilePath:($PSScriptRoot+"\Shortcut_BackUp.lnk") -TargetPath:($TargetPath) -Parameters:($Parameters.Replace("%1", "backupperscript:BackUp")) 
        CreateShortcut -shortcutFilePath:($PSScriptRoot+"\Shortcut_DryRun.lnk") -TargetPath:($TargetPath) -Parameters:($Parameters.Replace("%1", "backupperscript:DryRun")) 
        $command = "Get-ChildItem '$PSScriptRoot\log\*.log' | sort LastWriteTime | select -last 1 | Get-Content -Wait "
        CreateShortcut -shortcutFilePath:($PSScriptRoot+"\Shortcut_ViewLastLog.lnk") -TargetPath:("powershell") -Parameters:(" -nologo -command `"&{$command}`"" ) 
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
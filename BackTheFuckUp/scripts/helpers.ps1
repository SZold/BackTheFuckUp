
#include scripts
. ($PSScriptRoot+'\LogBook.ps1')
#end include scripts

function OpenLogBook{    
    if ($script:LogBook -eq $null) { 
        $result = loadLogBookConfigs -xmlConfigs $script:configXML.LogBook;
        [LogBook]$script:LogBook = [LogBook]::new($result); 
        $script:LogBook.LogBook_DefaultLogSource = ""; 
    }    
    $script:LogBook.doLog("-----------------------------------------------------", [LogBookType]::Log);
}

function CloseLogBook{    
    if ($script:LogBook -ne $null) { 
        $script:LogBook.doLog("-----------------------------------------------------", [LogBookType]::Log);
    }    
}

function doLog{
    Param(
      [string]$entry,
      [LogBookType]$Type = [LogBookType]::Log
    )
    
    if ($script:LogBook -eq $null) { OpenLogBook; }    
    $script:LogBook.doLog($entry, $Type);

}

function LogBook_TabIn([int]$num = 1){
    if ($script:LogBook -eq $null) { OpenLogBook; }     
    $script:LogBook.TabIn($num);
}

function LogBook_TabOut([int]$num = 1){
    if ($script:LogBook -eq $null) { OpenLogBook; }         
    $script:LogBook.TabOut($num);
}

function cutpad([string]$string, [int]$num){
    return $string.subString(0, [System.Math]::Min($num, $string.Length)).PadRight($num, " ") 
}

function doLogJob([System.Management.Automation.Job]$Job){        
    $Output = $Job.Information.ReadAll();
    
    LogBook_TabIn;
    #doLog -entry ("doLogJob |"+($Output.Count)+" | "+$Job.HasMoreData+"  | "+($Job | Get-Job).Name+" | ") -type debug
    if($Output.Count -gt 0){
        foreach($Out in $Output){
            #doLog -entry ("         doLogJob |"+$out.ToString()+" | ") -type debug
            [System.Management.Automation.InformationRecord]$IR =  $out;
            if($IR.Tags -notcontains "PSHOST"){
                $text = "["+(cutpad ($Job | Get-Job).Name -num 8)+"]["+(cutpad $out.tags[0] -num 8)+"] "+$IR.ToString();
                $logEntry = [LogEntry]::new($text, [LogBookType]::FullDetail, $script:Logbook);
                $logEntry.LogSource = ($Job | Get-Job).Name;
                $script:Logbook.doLogEntry($logEntry);
            }
        }
        $Job.Information.Clear();
    }
    LogBook_TabOut;
}

function doLogJobFull([System.Management.Automation.Job]$Job){        
    $Output = $Job.Information.ReadAll();
    
    LogBook_TabIn;
    if($Output.Count -gt 0){
        foreach($Out in $Output){
            [System.Management.Automation.InformationRecord]$IR =  $out;
            if($IR.Tags -notcontains "PSHOST"){
                $logEntry = [LogEntry]::new($IR.ToString(), $out.tags[0], $script:Logbook);
                $logEntry.LogSource = ($Job | Get-Job).Name;
                $script:Logbook.doLogEntry($out.tags[1]+$logEntry);
            }
        }
    }
    LogBook_TabOut;
    $Job.Information.Clear();
}

function loadLogBookConfigs($xmlConfigs){
    [OutputType([LogBookConfig])]
    [LogBook]$LogBook = [LogBook]::new(); 
    $LogBook.config.OutputConfigs += [LogBookOutputConfig]::new([LogBookOutput]::Console, [LogBookLevel]::Level7);
    $LogBook.config.OutputConfigs += [LogBookOutputConfig]::new([LogBookOutput]::File, [LogBookLevel]::Level1, "", "/../log/preConfigLogError.log", "");
    Try {

        [LogBookConfig]$result = [LogBookConfig]::new();

        $result.DateTimeFormat  = $xmlConfigs.DateTimeFormat
        $result.DeltaTimeFormat = $xmlConfigs.DeltaTimeFormat   
        $LogBook.doLog("Date formats loaded: DateTimeFormat: "+$result.DateTimeFormat+"; DeltaTimeFormat: "+$result.DeltaTimeFormat, [LogBookType]::FullDetail);
        $result.OutputConfigs = @();      
        foreach( $LogOutput in $xmlConfigs.LogOutput ){   
            [LogBookOutputConfig]$outputConfig =  [LogBookOutputConfig]::new();
            $outputConfig.Level = $LogOutput.level;
            $outputConfig.Output = $LogOutput.Type;
            $outputConfig.FileName = $LogOutput.FileName;
            $outputConfig.FileNameDateFormat = $LogOutput.FileNameDateFormat;
            $outputConfig.OutputFormat = $LogOutput.InnerText;

            $LogBook.doLog("logbook output config loaded: Level="+$outputConfig.Level+"; Output="+$outputConfig.Output+"; FileName="+$outputConfig.FileName+"; FileNameDateFormat="+
                            $outputConfig.FileNameDateFormat+"; OutputFormat="+$outputConfig.OutputFormat, [LogBookType]::FullDetail);

            $result.OutputConfigs += $outputConfig;
        }
        $LogBook.doLog("Logbook config loaded! ("+$result.OutputConfigs.Count+")", [LogBookType]::Success);
    } Catch  {      
        $LogBook.doLog("Unhandled exception occured: ", [LogBookType]::Error);
        $LogBook.doLog("'"+$_+"'", [LogBookType]::Exception);
    } 
    return $result;
}

function loadConfigs([string]$filename){ 
    [LogBook]$LogBook = [LogBook]::new(); 
    $LogBook.config.OutputConfigs += [LogBookOutputConfig]::new([LogBookOutput]::Console, [LogBookLevel]::Level7);
    $LogBook.config.OutputConfigs += [LogBookOutputConfig]::new([LogBookOutput]::File, [LogBookLevel]::Level1, "", "/../log/preConfigLogError.log", "");
    $LogBook.doLog("loadConfigs("+$filename+")", [LogBookType]::Detail);
    Try {
        $configFilePath = $filename
        If (Test-Path $configFilePath){   
            $configFile = gi $configFilePath 
            try { 
                [xml]$configXML = get-content -Path $configFile -Encoding UTF8;
                $script:configXML = $configXML.BackUpConfig;
                $LogBook.doLog("Config loaded!", [LogBookType]::Success);
            } catch {        
                $LogBook.doLog("Config load error: '"+$_+"'", [LogBookType]::Exception);     
            }
        
        }else{ 
           $LogBook.doLog("Config file not found error: '"+$configFilePath+"'", [LogBookType]::Exception); 
        }
    } Catch  {      
        $LogBook.doLog("Unhandled exception occured: ", [LogBookType]::Error);
        $LogBook.doLog("'"+$_+"'", [LogBookType]::Exception);
    } 
}

function checkAdminRights([bool]$fail = $true){
    $result = $false
    doLog -entry ("Check Admin Rights ($fail)") -Type Detail
    LogBook_TabIn;
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    if($currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)){
            $result = $true
            doLog -entry ("Has Admin Rights") -Type Success
    }else{
        if($fail){ 
            doLog -entry ("Admin Rights needed to continue") -Type Exception
        }else{
            doLog -entry ("No Admin Rights") -Type Error
        }
    }
    LogBook_TabOut;
    return $result;
}

function AddRegistryKey($key){    
    doLog -entry ("Check Registry key: ($key)") -Type FullDetail
    if(-Not (Test-Path -Path $key )){
        doLog -entry ("Add Registry key: ($key)") 
        LogBook_TabIn;
        if(checkAdminRights){
            try { 
                New-Item $key -ErrorAction Stop -Force | Out-Null
                doLog -entry ("Registry key added!") -Type Success 
            } catch {        
                doLog -entry ("Error Creating Registry key: '"+$_+"'") -Type Exception        
            }
        }
        LogBook_TabOut;
    }else{    
        doLog -entry ("Registry key Found ($key)") -Type FullDetail
    }
}

function AddRegistryEntry($key, $name, $value, $PropertyType = "String"){ 
    AddRegistryKey($key);  
    LogBook_TabIn;
    if( $null -eq (Get-ItemProperty -Path $key -Name $name -ErrorAction SilentlyContinue) ){
        doLog -entry ("Add Registry entry: ($key\$name)") 
        LogBook_TabIn;
        if(checkAdminRights){
            try { 
                New-ItemProperty -Path $key -Name $name -PropertyType $PropertyType -Value ($value) -Force -ErrorAction Stop | Out-Null
                doLog -entry ("Registry entry added! -Key $key -Name $name -Value $value -PropertyType $PropertyType") -Type Success 
            } catch {        
                doLog -entry ("Error Creating Registry entry: '"+$_+"'") -Type Exception        
            }
        }
        LogBook_TabOut;
    }else{    
        doLog -entry ("Registry entry Found ($key\$name)") -Type FullDetail
    }
    LogBook_TabOut;
}


Function CreateShortcut($shortcutFilePath, $TargetPath, $Parameters){
    $WshShell = New-Object -comObject WScript.Shell
    
    if(-Not (Test-Path -Path $shortcutFilePath )){
        doLog -entry ("Add Shortcut ($shortcutFilePath)")
        LogBook_TabIn;
        doLog -entry ("Shortcut TargetPath ($TargetPath)") -Type Detail
        doLog -entry ("Shortcut Arguments ("+$Parameters+")") -Type Detail
        $Shortcut = $WshShell.CreateShortcut($shortcutFilePath)
        $Shortcut.TargetPath = $TargetPath
        $Shortcut.Arguments = ($Parameters)
        $Shortcut.Save()
        doLog -entry ("Shortcut saved ($shortcutFilePath)") -Type Success
        LogBook_TabOut;
    }else{    
        doLog -entry ("Shortcut Found ($shortcutFilePath)") -Type Detail
    }
}

function GetFriendlySize($BytesParam) {
$Bytes = [math]::Abs($BytesParam);
    if ($Bytes -ge 1GB)
    {
        $Value = '{0:F2} {%FILESIZE_GB%}' -f ($Bytes / 1GB)
    }
    elseif ($Bytes -ge 1MB)
    {
        $Value = '{0:F2} {%FILESIZE_MB%}' -f ($Bytes / 1MB)
    }
    elseif ($Bytes -ge 1KB)
    {
        $Value = '{0:F2} {%FILESIZE_KB%}' -f ($Bytes / 1KB)
    }
    else
    {
        $Value = '{0} {%FILESIZE_BYTE%}' -f $Bytes
    }
    if($BytesParam -ne $Bytes){
        $Value = '-'+$Value;
    }
    doLog -entry ("GetFriendlySize ($BytesParam) = ($Value)") -Type FullDetail
    return $Value;
}

Function SplitURL($URL){
    doLog -entry ("SplitURL ($URL) ") -Type FullDetail
    LogBook_TabIn;
    if($URL.Length -gt 0){
        $InvokedFromURL = $true
        $fullURL = $URL.Split(':');
        if($fullURL[1].Length -gt 0){
            $params = $fullURL[1].Split('/');
            foreach($param in $params){
                $keyvalue = $param.Split('=');
                doLog -entry ("Param: "+$keyvalue[0]+"="+$keyvalue[1]) -Type FullDetail
            }
        }
    }
    LogBook_TabOut;
}

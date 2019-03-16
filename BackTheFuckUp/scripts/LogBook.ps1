Enum LogBookType
{  
     Log          = 1
     ChapterStart = 2
     ChapterEnd   = 4
     Error        = 8
     Exception    = 16
     Important    = 32
     Success      = 64
     Debug        = 128
     Detail       = 256
     FullDetail   = 512
     Loop         = 1024
}
Enum LogBookLevel
{  
     Level0 = 0
     Level1 = 1
     Level2 = 2
     Level3 = 3
     Level4 = 4
     Level5 = 5
     Level6 = 6
     Level7 = 7
}
Enum LogBookOutput
{  
    File    = 1
    Console = 2
    XML = 4
    Memory = 8
    ScriptOutput = 16
}

function LogBook_GetTabs($tab){
    $result = "";
    for($i=0;$i -le $tab; $i++){ 
        $result = $result + "    ";
    }
    return $result;
}

class LogBookOutputConfig{
    [LogBookOutput]$Output = [LogBookOutput]::new();
    [LogBookLevel]$Level = [LogBookLevel]::Level0
    [string]$FileName = "Log_{_FILENAMEDATEFORMAT_}.log"
    [string]$FileNameDateFormat = "yyyy-MM-dd"
    [string]$OutputFormat = "";
    
    LogBookOutputConfig(){
        $this.LogBookOutputConfigInit([LogBookOutput]::Memory, [LogBookLevel]::Level1, "", "yyyy-MM-dd HH:mm:ss.fff", "mm:ss.fff" );}
    LogBookOutputConfig([LogBookOutput]$Output, [LogBookLevel]$Level){
        $this.LogBookOutputConfigInit($Output, $level, "", "", "");}
    LogBookOutputConfig([LogBookOutput]$Output, [LogBookLevel]$Level, $OutputFormat){
        $this.LogBookOutputConfigInit($Output, $level, $OutputFormat, "", "");}
    LogBookOutputConfig([LogBookOutput]$Output, [LogBookLevel]$Level, $OutputFormat, $FileName, $FileNameDateFormat){
        $this.LogBookOutputConfigInit($Output, $level, $OutputFormat, $FileName, $FileNameDateFormat);}
    hidden LogBookOutputConfigInit([LogBookOutput]$Output, [LogBookLevel]$Level, $OutputFormat, $FileName, $FileNameDateFormat) { 
        $this.Output = $Output;
        $this.Level = $Level;
        $this.FileName = $FileName;
        $this.FileNameDateFormat = $FileNameDateFormat;
        $this.OutputFormat = $OutputFormat;
    }
}
class LogBookConfig{
    $DateTimeFormat;
    $DeltaTimeFormat;
    [LogBookOutputConfig[]]$OutputConfigs;
    
    LogBookConfig(){
        $this.LogBookConfigInit("yyyy-MM-dd HH:mm:ss.fff", "mm:ss.fff", @());}
    LogBookConfig([LogBookOutputConfig[]]$OutputConfigs){
        $this.LogBookConfigInit("yyyy-MM-dd HH:mm:ss.fff", "mm:ss.fff", $OutputConfigs);}
    LogBookConfig($DateTimeFormat, $DeltaTimeFormat, [LogBookOutputConfig[]]$OutputConfigs){
        $this.LogBookConfigInit($DateTimeFormat, $DeltaTimeFormat, $OutputConfigs);}
    hidden LogBookConfigInit($DateTimeFormat, $DeltaTimeFormat, [LogBookOutputConfig[]]$OutputConfigs) { 
        $this.DateTimeFormat = $DateTimeFormat;
        $this.DeltaTimeFormat = $DeltaTimeFormat;
        $this.OutputConfigs = $OutputConfigs;
    }
}

class LogEntry{
    $LogSource = "";
    $now = 0;
    $deltaStart = 0;
    $deltaLast = 0;
    $entry = "";
    $tab = "";
    $type = [LogBookType]::Log;
    [LogBook]$LogBook = $null;
    
    LogEntry($entry, $type, [LogBook]$LogBook){
        $this.LogEntryInit($entry, $type, $LogBook, "");}
    LogEntry($entry, $type, [LogBook]$LogBook, [string]$LogSource){
        $this.LogEntryInit($entry, $type, $LogBook, $LogSource);}

    hidden LogEntryInit($entry, $type, [LogBook]$LogBook, [string]$LogSource) { 
        $this.LogBook = $LogBook;
        $this.now = [System.DateTime]::Now;
        $this.deltaStart = $this.now.Add(-$this.LogBook.LogBook_StartTime);
        if($this.LogBook.LogBook_LastLogTime -ne 0){
            $this.deltaLast = $this.now.Add(-$this.LogBook.LogBook_LastLogTime);
        }else{
            $this.deltaLast = $this.now.Add(-$this.now)
        }
        $this.entry = $entry;
        $this.type = $type;        
        $this.tab = $this.LogBook.LogBook_Tab;
        if($LogSource.Length -gt 0){
            $this.LogSource = $LogSource
        }else{
            $this.LogSource = $LogBook.LogBook_DefaultLogSource;
        }
    }
    
    [string]getTabs(){
        return LogBook_GetTabs($this.tab);
    }
    
    [string]ToString(){
        return $this.ToString("");
    }
    
    [string]ToString([string]$OutputFormat){
        if($OutputFormat.length -gt 0){
            [string]$log = $OutputFormat;
        }else{
            [string]$log = "[{_LOGSOURCE8_}][{_CURRENT_DATETIME_}][{_TIME_DELTA_START_}][{_TIME_DELTA_PREV_}][{_USEDCPUPERC4_}][{_USEDMEMSIZE8_}][{_TYPE8_}]{_TABS_}{_ENTRY_}";
        }
        $cpuperc = 0# $this.LogBook.getCPUUsegePercent($script:ProcessId); //SZOLD - Takes 1 second for get-counter to get data. Get CPU usage in new job 
        $cpupercfriendly = $cpuperc.ToString()+"%";
        $memsize = $this.LogBook.getUsedMemorySize($script:ProcessId);
        $memsizefriendly = $this.LogBook.GetFriendlySize($memsize);
        $memperc = $this.LogBook.getUsedMemoryPercent($script:ProcessId).ToString()+"%";
        

        $log = $log.replace('{_USEDMEMSIZE_}',      $memsize);
        $log = $log.replace('{_USEDMEMSIZE8_}',     $memsizefriendly.subString(0, [System.Math]::Min(8, $memsizefriendly.Length)).PadRight(8, " ") );        
        $log = $log.replace('{_USEDMEMPERC_}',      $memperc);        
        $log = $log.replace('{_USEDMEMPERC4_}',     $memperc.subString(0, [System.Math]::Min(4, $memperc.Length)).PadRight(4, " ") );    
        $log = $log.replace('{_USEDCPUPERC_}',      $cpuperc.ToString().subString(0, [System.Math]::Min(4, $cpuperc.Length)).PadRight(4, " ") );        
        $log = $log.replace('{_USEDCPUPERC4_}',     $cpupercfriendly.subString(0, [System.Math]::Min(4, $cpupercfriendly.Length)).PadRight(4, " ") );

        $log = $log.replace('{_LOGSOURCE8_}',       $this.LogSource.ToString().subString(0, [System.Math]::Min(8, $this.LogSource.ToString().Length)).PadRight(8, " ") );
        $log = $log.replace('{_LOGSOURCE_}',        $this.LogSource.ToString());        
        $log = $log.replace('{_CURRENT_DATETIME_}', $this.now.ToString($this.LogBook.config.DateTimeFormat));
        $log = $log.replace('{_TIME_DELTA_START_}', $this.deltaStart.ToString($this.LogBook.config.DeltaTimeFormat));
        $log = $log.replace('{_TIME_DELTA_PREV_}',  $this.deltaLast.ToString($this.LogBook.config.DeltaTimeFormat));
        $log = $log.replace('{_TYPE8_}',            $this.type.ToString().subString(0, [System.Math]::Min(8, $this.type.ToString().Length)).PadRight(8, " ") );
        $log = $log.replace('{_TYPE_}',             $this.type.ToString());
        $log = $log.replace('{_TABS_}',             $this.getTabs());
        $log = $log.replace('{_ENTRY_}',            $this.entry);
        
        return $log;
    }
    [string]ToXML(){
        $log = ""
        $log += $this.getTabs()
        $log += "<Log ";
        $log += "Source=`""+($this.LogSource.ToString().subString(0, [System.Math]::Min(8, $this.LogSource.ToString().Length)).PadRight(8, " ") )+"`" "
        $log += "Type=`""+($this.type.ToString())+"`" ";
        $log += "LogTime=`""+($this.now.ToString($this.LogBook.config.DateTimeFormat))+"`" ";
        $log += "deltaStart=`""+($this.deltaStart.ToString($this.LogBook.config.DeltaTimeFormat))+"`" ";
        $log += "deltaLast=`""+($this.deltaLast.ToString($this.LogBook.config.DeltaTimeFormat))+"`">";
        $log += $this.entry;
        $log += "</"+($this.type.ToString())+">";
        return $log;
    }

}

class LogBook{
    [LogBookConfig]$config = [LogBookConfig]::new();
    $LogBook_StartTime = 0
    $LogBook_DefaultLogSource = "";
    $LogBook_LastLogTime = 0
    $LogBook_Tab = 0
    [LogEntry[]]$LogBook_Result = @();
    [LogBookLevel]$LogBook_Level = [LogBookLevel]::new();
    [LogBookOutput]$LogBook_Output = [LogBookOutput]::File -bor [LogBookOutput]::Console -bor [LogBookOutput]::XML;
    [LogBookType[]]$LogBookLevels = [LogBookType[]]::new([Enum]::GetValues([LogBookLevel]).Count);

    
    LogBook(){$this.LogBookInit($null);}
    LogBook($config){$this.LogBookInit($config);}
    hidden LogBookInit($config) { 
        if($null -eq $config){
            $this.config.DateTimeFormat  = "MM-dd-yyyy HH:mm:ss.fff"   
            $this.config.DeltaTimeFormat = "mm:ss.fff"   
            $this.config.OutputConfigs = @([LogBookOutputConfig]::new([LogBookOutput]::Memory, [LogBookLevel]::Level4));
        }else{
            $this.config = $config;
        }

        if($script:ProcessId -eq $null){
            $script:ProcessId = 0;
        }

        $this.LogBook_StartTime = [System.DateTime]::Now

        for($i = 0; $i -lt [Enum]::GetValues([LogBookLevel]).Count; $i++){
            $this.LogBookLevels[$i] = [LogBookType]::new();        
        }
        $this.LogBookLevels[[LogBookLevel]::Level0 -as [int]] = [LogBookType]::new();
        $this.LogBookLevels[[LogBookLevel]::Level1 -as [int]] = [LogBookType]::Error -bor [LogBookType]::Exception;
        $this.LogBookLevels[[LogBookLevel]::Level2 -as [int]] = [LogBookType]::ChapterStart -bor [LogBookType]::ChapterEnd;
        $this.LogBookLevels[[LogBookLevel]::Level3 -as [int]] = [LogBookType]::Important -bor [LogBookType]::Success;
        $this.LogBookLevels[[LogBookLevel]::Level4 -as [int]] = [LogBookType]::Log;
        $this.LogBookLevels[[LogBookLevel]::Level5 -as [int]] = [LogBookType]::Debug -bor [LogBookType]::Detail;
        $this.LogBookLevels[[LogBookLevel]::Level6 -as [int]] = [LogBookType]::FullDetail;
        $this.LogBookLevels[[LogBookLevel]::Level7 -as [int]] = [LogBookType]::Loop;
    }
    

    doLog([string]$entry, [LogBookType]$Type = [LogBookType]::Log){
        if($Type -eq [LogBookType]::ChapterEnd){ $this.TabOut(); }
        
        [LogEntry]$log = [LogEntry]::new($entry, $Type, $this);               
        $this.doLogEntry($log)            
        if($Type -eq [LogBookType]::ChapterStart){ $this.TabIn(); }        
        $this.LogBook_LastLogTime = $log.now;        

        if($Type -eq [LogBookType]::Exception){            
            exit 1
        }
    }

    doLogEntry([LogEntry]$log){    
        foreach($Output in $this.config.OutputConfigs ){ 
            if($this.isAllowed($Output.Level, $log.type)){
                if($Output.Output -eq [LogBookOutput]::Console)
                {
                    $this.WriteHost($log, $Output);
                }
                if($Output.Output -eq [LogBookOutput]::File)
                {
                    $this.WriteFile($log, $Output);
                }
                if($Output.Output -eq [LogBookOutput]::XML)
                {
                    $this.WriteXML($log, $Output);
                }    
                if($Output.Output -eq [LogBookOutput]::Memory)
                {
                    $this.LogBook_Result += $log;
                }    
                if($Output.Output -eq [LogBookOutput]::ScriptOutput)
                {
                    $this.WriteOutput($log, $Output);
                }                  
            }    
        }
    }
    
    TabIn(){$this.TabIn(1);}
    TabIn([int]$num = 1){        
        foreach($Output in $this.config.OutputConfigs ){
            if($Output.Type -band [LogBookOutput]::XML)
            {
                $entry = (LogBook_GetTabs($this.LogBook_Tab))
                $entry += "<Tab>"
                $this.WriteXML($entry, $Output);
            }
        }

        $this.LogBook_Tab += $num;
    }
    
    TabOut(){$this.TabOut(1);}
    TabOut([int]$num = 1){
        $this.LogBook_Tab -= $num;
        
        
        foreach($Output in $this.config.OutputConfigs ){
            if($Output.Type -band [LogBookOutput]::XML)
            {
                $entry = (LogBook_GetTabs($this.LogBook_Tab))
                $entry += "</Tab>"
                $this.WriteXML($entry, $Output);
            }
        }
    }
    
    WriteFile([LogEntry]$log, [LogBookOutputConfig]$Output){
        $filepath = $PSScriptRoot+$Output.FileName.replace("{_FILENAMEDATETIME_}", $this.LogBook_StartTime.ToString($Output.FileNameDateFormat))
        if (!(Test-Path $filepath)){
           New-Item $filepath -type "file" -Force | Out-Null
        }
        $log.ToString($Output.OutputFormat) | Out-File $filepath -Force -Append        
    }
    
    WriteXML([string]$line, [LogBookOutputConfig]$Output){
        $filepath = $PSScriptRoot+$Output.FileName.replace("{_FILENAMEDATETIME_}", $this.LogBook_StartTime.ToString($Output.FileNameDateFormat))
        if (!(Test-Path $filepath)){
           New-Item $filepath -type "file" -Force | Out-Null
        }
        $line.ToString($Output.OutputFormat) | Out-File $filepath -Force -Append         
    }
    WriteXML([LogEntry]$log, [LogBookOutputConfig]$Output){
        $filepath = $PSScriptRoot+$Output.FileName.replace("{_FILENAMEDATETIME_}", $this.LogBook_StartTime.ToString($Output.FileNameDateFormat))
        if (!(Test-Path $filepath)){
           New-Item $filepath -type "file" -Force | Out-Null
        }
        $log.ToString($Output.OutputFormat) | Out-File $filepath -Force -Append        
    }

    WriteHost_CharColor([string]$string){
        if($string.length -gt 0){            
            $hashByteArray = (new-object System.Security.Cryptography.MD5CryptoServiceProvider).ComputeHash([System.Text.Encoding]::UTF8.GetBytes($string))
            $hash = "";
            foreach($byte in $hashByteArray)
            {
                $hash += "{0:X2}" -f $byte
            }
            
            $charcount = ($hash.ToCharArray() | Where-Object {@('a', 'b', 'c', 'd', 'e', 'f') -contains $_} | Measure-Object).Count; 
            $backcolorNum = $charcount % ([enum]::GetValues([System.ConsoleColor]).Count ) 
            #[char]0x25A0 #[enum]::GetValues([System.ConsoleColor])[$backcolorNum].ToString().SubString(0,1)
            Write-Host " " -NoNewline -BackgroundColor ($backcolorNum )
        }else{
            Write-Host " " -NoNewline
        }
    }
    

    WriteOutput([LogEntry]$log, [LogBookOutputConfig]$Output){  
        Write-Information $log.ToString("{_ENTRY_}") -Tags @($log.Type, $log.ToString("{_TABS_}"))
        Write-Verbose $log.ToString($Output.OutputFormat);
        Write-Debug $log.ToString();
    }

    WriteHost([LogEntry]$log, [LogBookOutputConfig]$Output){  
        $this.WriteHost_CharColor($log.LogSource)  
        if($log.type -eq [LogBookType]::Exception){
            Write-Host ($log.ToString($Output.OutputFormat)) -foregroundcolor "red"  -backgroundcolor "black" 
        }
        elseif($log.type -eq [LogBookType]::Error){
            Write-Host ($log.ToString($Output.OutputFormat)) -foregroundcolor "red"  -backgroundcolor "black"
        }
        elseif($log.Type -eq [LogBookType]::Important){
            Write-Host ($log.ToString($Output.OutputFormat)) -foregroundcolor "Cyan"
        }
        elseif($log.Type -eq [LogBookType]::Success){
            Write-Host $log.ToString($Output.OutputFormat) -foregroundcolor "green" 
        }
        elseif($log.Type -eq [LogBookType]::ChapterStart){
            Write-Host $log.ToString($Output.OutputFormat) -foregroundcolor "blue"  -backgroundcolor "yellow" 
        }
        elseif($log.Type -eq [LogBookType]::ChapterEnd){
            Write-Host $log.ToString($Output.OutputFormat) -foregroundcolor "blue"  -backgroundcolor "Green"
        }
        elseif($log.Type -eq [LogBookType]::Debug){
            Write-Host $log.ToString($Output.OutputFormat) -foregroundcolor "white" -backgroundcolor "magenta"
        }
        elseif($log.Type -eq [LogBookType]::Detail){
            Write-Host $log.ToString($Output.OutputFormat) -foregroundcolor "white" 
        }
        elseif($log.Type -eq [LogBookType]::FullDetail){
            Write-Host $log.ToString($Output.OutputFormat) -foregroundcolor "Gray" 
        }
        elseif($log.Type -eq [LogBookType]::Loop){
            Write-Host $log.ToString($Output.OutputFormat) -foregroundcolor "DarkGray" 
        }
        else{
            Write-Host $log.ToString($Output.OutputFormat) -foregroundcolor "yellow" 
        }
    }

    [LogBookType]getAllowedTypes([LogBookLevel]$Level){
        [LogBookType]$allowed = [LogBookType]::new();  
        for ($i = ($Level -as [int]); $i -ge 0; $i--){
            $allowed = $allowed -bor $this.LogBookLevels[$i];
        }

        return $allowed;
    }

    [bool]isAllowed( [LogBookLevel]$Level, [LogBookType]$LogBookType){ 
        return ($this.getAllowedTypes($Level) -band $LogBookType);
    }
    
    [int32]getUsedMemorySize($ProcessId = $pid){
        (Get-process -Id $ProcessId | Select { $_.NonpagedSystemMemorySize });

        $result = Get-process -Id $ProcessId | Select { $_.NonpagedSystemMemorySize };
        return ($result.' $_.NonpagedSystemMemorySize ') ;
    }
    
    [int32]getUsedMemoryPercent($ProcessId = $pid){
        $totalMem = [Math]::Round((Get-WmiObject -Class win32_computersystem -ComputerName localhost).TotalPhysicalMemory/1Kb);
        $usedMem = $this.getUsedMemorySize($ProcessId);
        return ($usedMem / $totalMem);
    }

    [int32]getCPUUsegePercent($ProcessId = $pid){
        # To match the CPU usage to for example Process Explorer you need to divide by the number of cores
        $cpu_cores = (Get-WMIObject Win32_ComputerSystem).NumberOfLogicalProcessors

        # This is to find the exact counter path, as you might have multiple processes with the same name
        $proc_path = ((Get-Counter "\Process(*)\ID Process").CounterSamples | ? {$_.RawValue -eq $ProcessId}).Path

        # We now get the CPU percentage
        $prod_percentage_cpu = [Math]::Round(((Get-Counter ($proc_path -replace "\\id process$","\% Processor Time")).CounterSamples.CookedValue) / $cpu_cores)

        return $prod_percentage_cpu;
    }
    
    [string]GetFriendlySize($BytesParam) {
        $Bytes = [math]::Abs($BytesParam);
        if ($Bytes -ge 1GB)
        {
            $Value = '{0:F2}GB' -f ($Bytes / 1GB)
        }
        elseif ($Bytes -ge 1MB)
        {
            $Value = '{0:F2}MB' -f ($Bytes / 1MB)
        }
        elseif ($Bytes -ge 1KB)
        {
            $Value = '{0:F2}KB' -f ($Bytes / 1KB)
        }
        else
        {
            $Value = '{0}B' -f $Bytes
        }
        if($BytesParam -ne $Bytes){
            $Value = '-'+$Value;
        }
        return $Value;
    }
}


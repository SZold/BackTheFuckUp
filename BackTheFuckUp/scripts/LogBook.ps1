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
}
Enum LogBookOutput
{  
    File    = 1
    Console = 2
    XML = 4
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
    $FileNameDateFormat = "yyyy-MM-dd-HH"
    [LogBookLevel]$Level = [LogBookLevel]::Level0
    $FileName = "Log_{_FILENAMEDATEFORMAT_}.log"
}
class LogBookConfig{
    $DateTimeFormat  = "yyyy-MM-dd HH:mm:ss.fff"
    $DeltaTimeFormat = "mm:ss.fff"

    [LogBookOutputConfig[]]$OutputConfigs = @()
}

class LogEntry{
    $now = 0;
    $deltaStart = 0;
    $deltaLast = 0;
    $entry = "";
    $tab = "";
    $type = [LogBookType]::Log;
    [LogBook]$LogBook = $null;

    LogEntry($entry, $type, [LogBook]$LogBook){
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
    }
    
    [string]getTabs(){
        return LogBook_GetTabs($this.tab);
    }
    
    [string]ToString(){
        $log = ""
        $log += "["+($this.now.ToString($this.LogBook.config.DateTimeFormat))+"]";
        $log += "["+($this.deltaStart.ToString($this.LogBook.config.DeltaTimeFormat))+"]";
        $log += "["+($this.deltaLast.ToString($this.LogBook.config.DeltaTimeFormat))+"]";
        $log += "["+($this.type.ToString().subString(0, [System.Math]::Min(8, $this.type.ToString().Length)).PadRight(8, " ") )+"]";

        $log += " "+$this.getTabs()+$this.entry;
        return $log;
    }
    [string]ToXML(){
        $log = ""
        $log += $this.getTabs()
        $log += "<Log ";
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
    $LogBook_LastLogTime = 0
    $LogBook_Tab = 0
    [LogBookLevel]$LogBook_Level = [LogBookLevel]::new();
    [LogBookOutput]$LogBook_Output = [LogBookOutput]::File -bor [LogBookOutput]::Console -bor [LogBookOutput]::XML;
    [LogBookType[]]$LogBookLevels = [LogBookType[]]::new([Enum]::GetValues([LogBookLevel]).Count);

    
    LogBook(){$this.Init($null);}
    LogBook($config){$this.Init($config);}
    hidden Init($config) { 
        if($null -eq $config){
            $outputConfig =  [LogBookOutputConfig]::new();
            $outputConfig.Level = [LogBookLevel]::Level1;
            $outputConfig.Output = [LogBookOutput]::Console;

            $this.config.DateTimeFormat  = "MM-dd-yyyy HH:mm:ss.fff"   
            $this.config.DeltaTimeFormat = "mm:ss.fff"   
            $this.config.OutputConfigs = @($outputConfig);
        }else{
            $this.config = $config;
        }

        $this.LogBook_StartTime = [System.DateTime]::Now
        $this.LogBook_Level = [LogBookLevel]::Level5;

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
    }


    doLog([string]$entry, [LogBookType]$Type = [LogBookType]::Log){
        if($Type -eq [LogBookType]::ChapterEnd){ $this.TabOut(); }

        [LogEntry]$log = [LogEntry]::new($entry, $Type, $this);        
        foreach($Output in $this.config.OutputConfigs ){ 
            if($this.isAllowed($Output.Level, $Type)){
                if($Output.Output -eq [LogBookOutput]::Console)
                {
                    $this.WriteHost($log);
                }
                if($Output.Output -eq [LogBookOutput]::File)
                {
                    $this.WriteFile($log, $Output);
                }
                if($Output.Output -eq [LogBookOutput]::XML)
                {
                    $this.WriteXML($log, $Output);
                }                
            }    
        }
        
    
        if($Type -eq [LogBookType]::ChapterStart){ $this.TabIn(); }

        $this.LogBook_LastLogTime = $log.now;

        if($Type -eq [LogBookType]::Exception){            
            exit 1
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
        $filepath = $PSScriptRoot+$Output.FileName.replace("{_FILENAMEDATEFORMAT_}", $this.LogBook_StartTime.ToString($Output.FileNameDateFormat))
        if (!(Test-Path $filepath)){
           New-Item $filepath -type "file" -Force | Out-Null
        }
        $log.ToString() | Out-File $filepath -Force -Append        
    }
    
    WriteXML([string]$line, [LogBookOutputConfig]$Output){
        $filepath = $PSScriptRoot+$Output.FileName.replace("{_FILENAMEDATEFORMAT_}", $this.LogBook_StartTime.ToString($Output.FileNameDateFormat))
        if (!(Test-Path $filepath)){
           New-Item $filepath -type "file" -Force | Out-Null
        }
        $line.ToString() | Out-File $filepath -Force -Append         
    }
    WriteXML([LogEntry]$log, [LogBookOutputConfig]$Output){
        $filepath = $PSScriptRoot+$Output.FileName.replace("{_FILENAMEDATEFORMAT_}", $this.LogBook_StartTime.ToString($Output.FileNameDateFormat))
        if (!(Test-Path $filepath)){
           New-Item $filepath -type "file" -Force | Out-Null
        }
        $log.ToString() | Out-File $filepath -Force -Append        
    }

    WriteHost([LogEntry]$log){    
        if($log.type -eq [LogBookType]::Exception){
            Write-Host ($log.ToString()) -foregroundcolor "red"  -backgroundcolor "black" 
        }
        elseif($log.type -eq [LogBookType]::Error){
            Write-Host ($log.ToString()) -foregroundcolor "red"  -backgroundcolor "black"
        }
        elseif($log.Type -eq [LogBookType]::Important){
            Write-Host ($log.ToString()) -foregroundcolor "Cyan"
        }
        elseif($log.Type -eq [LogBookType]::Success){
            Write-Host $log.ToString() -foregroundcolor "green" 
        }
        elseif($log.Type -eq [LogBookType]::ChapterStart){
            Write-Host $log.ToString() -foregroundcolor "blue"  -backgroundcolor "yellow" 
        }
        elseif($log.Type -eq [LogBookType]::ChapterEnd){
            Write-Host $log.ToString() -foregroundcolor "blue"  -backgroundcolor "Green"
        }
        elseif($log.Type -eq [LogBookType]::Debug){
            Write-Host $log.ToString() -foregroundcolor "white" -backgroundcolor "magenta"
        }
        elseif($log.Type -eq [LogBookType]::Detail){
            Write-Host $log.ToString() -foregroundcolor "Gray" 
        }
        elseif($log.Type -eq [LogBookType]::FullDetail){
            Write-Host $log.ToString() -foregroundcolor "DarkGray" 
        }
        else{
            Write-Host $log.ToString() -foregroundcolor "yellow" 
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
}


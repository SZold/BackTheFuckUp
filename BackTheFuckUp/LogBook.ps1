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
    $FileNameDateFormat = "yyyy-MM-dd-HH"
    $Level = [LogBookLevel]::Level0
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

    LogEntry($entry, $type, $tab, $StartTime, $LastTime){
        $this.now = [System.DateTime]::Now;
        $this.deltaStart = $this.now.Add(-$StartTime);
        $this.deltaLast = $this.now.Add(-$LastTime);
        $this.entry = $entry;
        $this.type = $type;
        $this.tab = $tab;
    }
    
    [string]getTabs(){
        return LogBook_GetTabs($this.tab);
    }
    
    [string]ToString(){
        $log = ""
        $log += "["+($this.now.ToString("yyyy-MM-dd HH:mm:ss.fff"))+"]";
        $log += "["+($this.deltaStart.ToString("mm:ss.fff"))+"]";
        $log += "["+($this.deltaLast.ToString("mm:ss.fff"))+"]";
        $log += "["+($this.type.ToString().subString(0, [System.Math]::Min(8, $this.type.ToString().Length)).PadRight(8, " ") )+"]";

        $log += " "+$this.getTabs()+$this.entry;
        return $log;
    }
    [string]ToXML(){
        $log = ""
        $log += $this.getTabs()
        $log += "<Log ";
        $log += "Type=`""+($this.type.ToString())+"`" ";
        $log += "LogTime=`""+($this.now.ToString("yyyy-MM-dd HH:mm:ss.fff"))+"`" ";
        $log += "deltaStart=`""+($this.deltaStart.ToString("mm:ss.fff"))+"`" ";
        $log += "deltaLast=`""+($this.deltaLast.ToString("mm:ss.fff"))+"`">";
        $log += $this.entry;
        $log += "</"+($this.type.ToString())+">";
        return $log;
    }

}

class LogBook{
    $LogBook_LogFileName = ""
    $LogBook_LogXMLName = ""
    $LogBook_StartTime = 0
    $LogBook_LastLogTime = 0
    $LogBook_Tab = 0
    [LogBookLevel]$LogBook_Level = [LogBookLevel]::new();
    [LogBookOutput]$LogBook_Output = [LogBookOutput]::File -bor [LogBookOutput]::Console -bor [LogBookOutput]::XML;
    [LogBookType[]]$LogBookLevels = [LogBookType[]]::new([Enum]::GetValues([LogBookLevel]).Count);

    LogBook(){
        $this.LogBook_StartTime = [System.DateTime]::Now
        $this.LogBook_Level = [LogBookLevel]::Level5;
        $this.LogBook_LogFileName = $PSScriptRoot+"\log\Log_"+($this.LogBook_StartTime.ToString("yyyy-MM-dd-HH"))+".log"
        $this.LogBook_LogXMLName = $PSScriptRoot+"\log\Log_"+($this.LogBook_StartTime.ToString("yyyy-MM-dd-HH"))+".xml"

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

        [LogEntry]$log = [LogEntry]::new($entry, $Type, $this.LogBook_Tab, $this.LogBook_StartTime, $this.LogBook_LastLogTime);
        
        if(($this.LogBook_Output -band [LogBookOutput]::Console) -and
            $this.isAllowed([LogBookLevel]::Level6, $Type))
        {
            $this.WriteHost($log);
        }
        if(($this.LogBook_Output -band [LogBookOutput]::File) -and
            $this.isAllowed([LogBookLevel]::Level6, $Type))
        {
            $this.WriteFile($log);
        }
        if(($this.LogBook_Output -band [LogBookOutput]::XML) -and
            $this.isAllowed([LogBookLevel]::Level6, $Type))
        {
            $this.WriteXML($log);
        }
    
        if($Type -eq [LogBookType]::ChapterStart){ $this.TabIn(); }

        $this.LogBook_LastLogTime = $log.now;
    }
    
    TabIn(){$this.TabIn(1);}
    TabIn([int]$num = 1){
        $entry = (LogBook_GetTabs($this.LogBook_Tab))
        $entry += "<Tab>"
        $this.WriteXML($entry);

        $this.LogBook_Tab += $num;
    }
    
    TabOut(){$this.TabOut(1);}
    TabOut([int]$num = 1){
        $this.LogBook_Tab -= $num;

        $entry = (LogBook_GetTabs($this.LogBook_Tab) )
        $entry += "</Tab>"
        $this.WriteXML($entry);
    }
    
    WriteFile([LogEntry]$log){
        if (!(Test-Path $this.LogBook_LogFileName)){
           New-Item $this.LogBook_LogFileName -type "file" -Force | Out-Null
        }
        $log.ToString() | Out-File $this.LogBook_LogFileName -Force -Append        
    }
    
    WriteXML([string]$line){
        if (!(Test-Path $this.LogBook_LogXMLName)){
           New-Item $this.LogBook_LogXMLName -type "file" -Force | Out-Null
        }
        $line | Out-File $this.LogBook_LogXMLName -Force -Append        
    }
    WriteXML([LogEntry]$log){
        if (!(Test-Path $this.LogBook_LogXMLName)){
           New-Item $this.LogBook_LogXMLName -type "file" -Force | Out-Null
        }
        $log.ToXML() | Out-File $this.LogBook_LogXMLName -Force -Append        
    }

    WriteHost([LogEntry]$log){    
        if($log.type -eq [LogBookType]::Exception){
            #Write-Error ($log.ToString())
            Write-Host ($log.ToString()) -foregroundcolor "red"  -backgroundcolor "black" 
            exit 1
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


#include scripts
. ($PSScriptRoot+'\helpers.ps1')
#end include scripts

Enum BackUpperCompareType
{  
 Size
 ModificationDate 
 ExtensionAllowed
}

Enum BackUpperActionType
{
 Nothing = [math]::pow( 2, 0 )
 SaveToTarget = [math]::pow( 2, 1 )
 DeleteFromTarget = [math]::pow( 2, 2 )
 SaveNewVersionToTarget = [math]::pow( 2, 3 )
}

class BackUpperFile
{
    [BackUpperActionType]$actionType
    [string]$relativePath

    BackUpperFile([string]$relativePath, [BackUpperActionType]$actionType) {
       $this.relativePath = $relativePath;
       $this.actionType = $actionType; 
    }
}

class BackUpperStats{
    [int64] $FileCount = 0;
    [int64] $FileSizeDelta = 0;
    [int64] $FileSizeSum = 0;
}

class BackUpper
{
    [string]$SourcePath
    [string]$TargetPath 
    [bool]$considerAllTargets    
    [BackUpperCompareType]$compareType
    [string[]]$WhiteListedExtensions
    [string[]]$BlackListedExtensions

    BackUpper([string]$SourcePath, [string]$TargetPath) {
       $this.SourcePath = (Resolve-Path ($SourcePath + '\')).Path;
       $this.TargetPath = (Resolve-Path ($TargetPath + '\')).Path;    
       $this.compareType = [BackUpperCompareType]::Size + [BackUpperCompareType]::ModificationDate #+ [BackUpperCompareType]::ExtensionAllowed
       $this.considerAllTargets = $true
    }

    [System.Object]findFilteredFiles([string]$path){
        doLog -entry ("Find filtered files") 
        LogBook_TabIn;
        $FilteredList = @();
        if(Test-Path -Path $path){
            $FileList = Get-ChildItem -Path $path -Recurse  
            $FilteredList  = $FileList | foreach {$_.FullName};

            if($FilteredList.Length -gt 0){
                if (($this.WhiteListedExtensions.Count -gt 0) -and ($this.BlackListedExtensions.Count -eq 0)){
                    $FilteredList  = $FileList | where {$this.WhiteListedExtensions -contains $_.Extension } | foreach {$_.FullName}
                    doLog -entry ("Filter to Whitelist | ("+$this.WhiteListedExtensions+") | FilteredList.count = "+$FilteredList.Length+" ") -Type Detail
                }elseif (($this.WhiteListedExtensions.Count -eq 0) -and ($this.BlackListedExtensions.Count -gt 0)){
                    $FilteredList  = $FileList | where {$this.BlackListedExtensions -notcontains $_.Extension} | foreach {$_.FullName}
                    doLog -entry ("Filter to Blacklist | ("+$this.BlackListedExtensions+") | FilteredList.count = "+$FilteredList.Length+" ") -Type Detail
                }elseif (($this.WhiteListedExtensions.Count -gt 0) -and ($this.BlackListedExtensions.Count -gt 0)){
                    doLog -entry "Cannot add both a White and a Black list" -Type Exception
                }else{
                    doLog -entry ("Do not Filter") -Type FullDetail
                }
            }
        }else{
            doLog -entry ("Path not found | ("+$path+")") -Type Exception
        }   
        LogBook_TabOut;
        return $FilteredList;
    }    

    [System.Object]findTargetFiles(){
        doLog -entry ("Find target files") 
        LogBook_TabIn;
        doLog -entry ("this.considerAllTargets = ("+$this.considerAllTargets+")") -Type Detail
        $TargetFiles = @(); 
        if($this.considerAllTargets -eq $true){
            if(Test-Path -Path $this.TargetPath){
                $TargetFiles = Get-ChildItem -Path $this.TargetPath -Recurse -ErrorAction SilentlyContinue | foreach {$_.FullName};
                if($null -eq $TargetFiles){
                    $TargetFiles = @();
                }            
            }else{
                doLog -entry ("Path not found | ("+$this.TargetPath+")") -Type Exception
            }   
            doLog -entry ("findTargetFiles().TargetFiles.count  = ("+$TargetFiles.Count+")") -Type Detail
        }else{
            $TargetFiles = $this.findFilteredFiles($this.TargetPath);
        }    
        LogBook_TabOut;
        return $TargetFiles;
    }

    [BackUpperActionType]compareFiles($sourceFileInfo, $targetFileInfo){   
        doLog -entry ("sourceFileInfo: ("+($sourceFileInfo)+")") -Type FullDetail
        doLog -entry ("sourceFileInfo.Length: ("+($sourceFileInfo.Length)+")") -Type FullDetail
        doLog -entry ("sourceFileInfo.LastWriteTime: ("+($sourceFileInfo.LastWriteTime)+")") -Type FullDetail
        doLog -entry ("targetFileInfo: ("+($targetFileInfo)+")") -Type FullDetail
        doLog -entry ("targetFileInfo.Length: ("+($targetFileInfo.Length)+")") -Type FullDetail
        doLog -entry ("targetFileInfo.LastWriteTime: ("+($targetFileInfo.LastWriteTime)+")") -Type FullDetail
    
        $relativeFilePath = if ($sourceFileInfo -eq $null) { $this.getRelativePath($targetFileInfo.Fullname) } else {$this.getRelativePath($sourceFileInfo.Fullname) }

        if($this.compareType -band [BackUpperCompareType]::ExtensionAllowed){
            if(($this.BlackListedExtensions -contains $sourceFileInfo.Extension) -or
               ($this.WhiteListedExtensions -notcontains $sourceFileInfo.Extension))
            {
                doLog -entry ("Action: File extension not allowed | File: '"+($relativeFilePath)+"'") -Type Detail
                return [BackUpperActionType]::DeleteFromTarget;
            }
        }
        if(($sourceFileInfo.Exists -ne $true) -And ($targetFileInfo.Exists -eq $true)){
             doLog -entry ("Action: File deleted from source | File: '"+($relativeFilePath)+"'") -Type Detail
             return [BackUpperActionType]::DeleteFromTarget;
        }
        if(($sourceFileInfo.Exists -eq $true) -And ($targetFileInfo.Exists -ne $true)){
             doLog -entry ("Action: File not on target | File: '"+($relativeFilePath)+"'") -Type Detail 
             return [BackUpperActionType]::SaveToTarget;
        }
        if($this.compareType -band [BackUpperCompareType]::ModificationDate){
            if($sourceFileInfo.LastWriteTime -ne $targetFileInfo.LastWriteTime){            
                if($sourceFileInfo.LastWriteTime -gt $targetFileInfo.LastWriteTime){
                    doLog -entry ("Action: File newer on source | File: '"+($relativeFilePath)+"'") -Type Detail
                    return [BackUpperActionType]::SaveNewVersionToTarget;
                }else{
                    doLog -entry ("Action: File newer on target | File: '"+($relativeFilePath)+"'") -Type Detail
                    return [BackUpperActionType]::SaveToTarget;
                }
            }
        }
        if($this.compareType -band [BackUpperCompareType]::Size){
            if($sourceFileInfo.Length -ne $targetFileInfo.Length){
                doLog -entry ("Action: File size different | File: '"+($relativeFilePath)+"'") -Type Detail
                return [BackUpperActionType]::SaveToTarget;
            }
        }
         
        doLog -entry ("Action: File already backed up | File: '"+($relativeFilePath)+"'") -Type FullDetail
        return [BackUpperActionType]::Nothing;
    }

    [string]getRelativePath([string]$FullFileName){
        $RelativePath = $FullFileName.Replace($this.SourcePath, "");
        if($FullFileName -eq $RelativePath){
            $RelativePath = $FullFileName.Replace($this.TargetPath, "");
        }
        
        return $RelativePath;
    }
    
    [BackUpperStats[]]doBackUp([bool]$DryRun = $false){ 
        doLog -entry ("doBackUp($DryRun)") -Type ChapterStart

        [BackUpperStats[]]$result = [BackUpperStats[]]::new([Enum]::GetValues([BackUpperActionType]).Count);
        for($i = 0; $i -lt [Enum]::GetValues([BackUpperActionType]).Count; $i++){
            $result[$i] = [BackUpperStats]::new();        
        }
        
        $SourceFiles = $this.findFilteredFiles($this.SourcePath);
        $TargetFiles = $this.findTargetFiles();

        doLog -entry ("Remove Duplicates") 
        LogBook_TabIn;
        $i = 0;
        $combinedFiles0 = ($SourceFiles + $TargetFiles) 
        $combinedFiles = ($SourceFiles + $TargetFiles)  | foreach {$this.getRelativePath($_)} | Sort-Object -Unique
        doLog -entry ("Removed Duplicates ("+($combinedFiles0.length - $combinedFiles.length)+")") -Type Detail
        LogBook_TabOut;
        
        doLog -entry ("Loop through all files") 
        LogBook_TabIn;
        Foreach($relativeFilePath in $combinedFiles){
            $i++;
            
            $percent = [math]::Floor((($I / $combinedFiles.Count)*100));
            Write-Progress -Activity "Gathering file informations" -Status "$percent% Complete:" -PercentComplete $percent -CurrentOperation "Current: '$relativeFilePath'";

            $sourceFileInfo = Get-ItemProperty -LiteralPath ($this.SourcePath+$relativeFilePath)
            $targetFileInfo = Get-ItemProperty -LiteralPath ($this.TargetPath+$relativeFilePath)  
             
            doLog -entry ("File: ("+($relativeFilePath)+")") -Type FullDetail
            LogBook_TabIn;
            doLog -entry ("this.SourcePath+relativeFilePath: ("+($this.SourcePath+$relativeFilePath)+")") -Type FullDetail
            doLog -entry ("this.TargetPath+relativeFilePath: ("+($this.TargetPath+$relativeFilePath)+")") -Type FullDetail
            #doLog -entry ("$percent% Complete | File: '"+$relativeFilePath+"'") -Type ([LogBookType]::Detail)
            $actionType = $this.compareFiles($sourceFileInfo, $targetFileInfo);
            doLog -entry ("actionType: ("+($actionType)+")") -Type FullDetail
            
            $result[($actionType -as [int64])].FileCount++;
            if($actionType -ne [BackUpperActionType]::Nothing){              
                if($actionType -ne [BackUpperActionType]::Nothing){ 
                    $result[($actionType -as [int64])].FileSizeSum += $sourceFileInfo.Length;
                }                     
                if($actionType -eq [BackUpperActionType]::SaveNewVersionToTarget){
                    $result[($actionType -as [int64])].FileSizeDelta += $sourceFileInfo.Length;
                }else{
                    $result[($actionType -as [int64])].FileSizeDelta += $sourceFileInfo.Length - $targetFileInfo.Length;
                }
            }
            LogBook_TabOut;
        } 
        LogBook_TabOut;
        doLog -entry ("doBackUp($DryRun) finished!") -Type ChapterEnd
        return $result;
    }
}

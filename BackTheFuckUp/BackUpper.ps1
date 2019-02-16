Enum BackUpperCompareType
{  
 Size
 ModificationDate 
 ExtensionAllowed
}

Enum BackUpperActionType
{
 Nothing = 0
 SaveToTarget = 1
 DeleteFromTarget = 2
 SaveNewVersionToTarget = 3
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
    [int] $FileCount = 0;
    [int] $FileSizeDelta = 0;
    [int] $FileSizeSum = 0;
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
       $this.SourcePath = $SourcePath + '\';
       $this.TargetPath = $TargetPath + '\';     
       $this.compareType = [BackUpperCompareType]::Size + [BackUpperCompareType]::ModificationDate #+ [BackUpperCompareType]::ExtensionAllowed
       $this.considerAllTargets = $true
    }

    [System.Object]findFilteredFiles([string]$path){
        $FileList = Get-ChildItem -Path $path -Recurse 
        $FilteredList  = $FileList;

        if($FilteredList.Length -gt 0){
            if (($this.WhiteListedExtensions.Count -gt 0) -and ($this.BlackListedExtensions.Count -eq 0)){
                $FilteredList  = $FileList | where {$this.WhiteListedExtensions -contains $_.extension }
            }elseif (($this.WhiteListedExtensions.Count -eq 0) -and ($this.BlackListedExtensions.Count -gt 0)){
                $FilteredList  = $FileList | where {$this.BlackListedExtensions -notcontains $_.extension }
            }elseif (($this.WhiteListedExtensions.Count -gt 0) -and ($this.BlackListedExtensions.Count -gt 0)){
                Write-Error "Cannot add both a White and a Black list"
            }
        }
            
        return $FilteredList;
    }    

    [System.Object]findTargetFiles(){
        if($this.considerAllTargets -eq $true){
            $TargetFiles = Get-ChildItem -Path $this.TargetPath -Recurse; 
        }else{
            $TargetFiles = $this.findFilteredFiles($this.TargetPath);
        }    
            
        return $TargetFiles;
    }

    [BackUpperActionType]compareFiles($sourceFileInfo, $targetFileInfo){     
        if($this.compareType -band [BackUpperCompareType]::ExtensionAllowed){
            if(($this.BlackListedExtensions -contains $sourceFileInfo.Extension) -or
               ($this.WhiteListedExtensions -notcontains $sourceFileInfo.Extension))
            {
                return [BackUpperActionType]::DeleteFromTarget;
            }
        }
        if(($sourceFileInfo.Exists -ne $true) -And ($targetFileInfo.Exists -eq $true)){
             return [BackUpperActionType]::DeleteFromTarget;
        }
        if(($sourceFileInfo.Exists -eq $true) -And ($targetFileInfo.Exists -ne $true)){
             return [BackUpperActionType]::SaveToTarget;
        }
        if($this.compareType -band [BackUpperCompareType]::ModificationDate){
            if($sourceFileInfo.LastWriteTime -ne $targetFileInfo.LastWriteTime){            
                if($sourceFileInfo.LastWriteTime -gt $targetFileInfo.LastWriteTime){
                    return [BackUpperActionType]::SaveNewVersionToTarget;
                }else{
                    return [BackUpperActionType]::SaveToTarget;
                }
            }
        }
        if($this.compareType -band [BackUpperCompareType]::Size){
            if($sourceFileInfo.Length -ne $targetFileInfo.Length){
                return [BackUpperActionType]::SaveToTarget;
            }
        }

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
        [BackUpperStats[]]$result = [BackUpperStats[]]::new([Enum]::GetValues([BackUpperActionType]).Count);
        for($i = 0; $i -lt [Enum]::GetValues([BackUpperActionType]).Count; $i++){
            $result[$i] = [BackUpperStats]::new();        
        }
        
        $SourceFiles = $this.findFilteredFiles($this.SourcePath);
        $TargetFiles = $this.findTargetFiles();

        $i = 0;
        $combinedFiles = ($SourceFiles + $TargetFiles) | select -uniq;

        Foreach($File in $combinedFiles){
            $i++;

            $relativeFilePath = $this.getRelativePath($File.Fullname)
            $sourceFileInfo = Get-ItemProperty ($this.SourcePath+$relativeFilePath)
            $targetFileInfo = Get-ItemProperty ($this.TargetPath+$relativeFilePath)   
            $actionType = $this.compareFiles($sourceFileInfo, $targetFileInfo);
            
            $result[($actionType -as [int])].FileCount++;
            if($actionType -ne [BackUpperActionType]::Nothing){              
                if($actionType -ne [BackUpperActionType]::Nothing){ 
                    $result[($actionType -as [int])].FileSizeSum += $sourceFileInfo.Length;
                }                     
                if($actionType -eq [BackUpperActionType]::SaveNewVersionToTarget){
                    $result[($actionType -as [int])].FileSizeDelta += $sourceFileInfo.Length;
                }else{
                    $result[($actionType -as [int])].FileSizeDelta += $sourceFileInfo.Length - $targetFileInfo.Length;
                }
            }
        }    
        return $result;
    }
}

Enum BackUpperCompareType
{  
 Size
 ModificationDate 
 ExtensionAllowed
}

Enum BackUpperActionType
{
 SaveToTarget
 SaveNewVersionToTarget
 Nothing
 DeleteFromTarget
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

    [BackUpperActionType]compareFiles($relativeFilePath){
        $sourceFileInfo = Get-ItemProperty ($this.SourcePath+$relativeFilePath)
        $targetFileInfo = Get-ItemProperty ($this.TargetPath+$relativeFilePath)        

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
                Write-Host "size dif"
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
    
    [BackUpperFile[]]doDryRun(){   

        [BackUpperFile[]]$result = @();
        
        $SourceFiles = $this.findFilteredFiles($this.SourcePath);
        $TargetFiles = $this.findTargetFiles();

        $i = 0;
        Foreach($File in ($SourceFiles + $TargetFiles)){
            $i++;

            $RelativePath = $this.getRelativePath($File.Fullname)
            
            $result += [BackUpperFile]::new($RelativePath, $this.compareFiles($RelativePath));
        }        

        return $result;
    }
    
    [void]doBackUp(){
        $this.doBackUp($this.doDryRun());
    }

    [void]doBackUp([BackUpperFile[]]$dryRunResult){
    
        $ProgressBar = New-BTProgressBar -Status ('Backing up "'+$this.SourcePath+'"') -Indeterminate
        New-BurntToastNotification –Text (‘Backing up from "'+$this.SourcePath+'"’) -ProgressBar $ProgressBar –UniqueIdentifier 'sajt001' 

        foreach($backUpFile in $dryRunResult){
            
        }
        sleep(5)
        New-BurntToastNotification –Text (‘Backing up from "'+$this.SourcePath+'" Done’)  –UniqueIdentifier 'sajt001' 
    }
}

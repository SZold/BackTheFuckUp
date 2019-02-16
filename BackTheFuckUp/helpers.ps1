function AddRegistryEntries($protocolName, $ProceedAction){
    $registryPath = 'Registry::HKEY_CLASSES_ROOT\'+$protocolName
    
    if(-Not (Test-Path -Path $registryPath )){
        $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
        if($currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)){
            New-Item $registryPath  -Force | New-ItemProperty -Name '(default)' -PropertyType String -Value ("URL:"+$protocolName+" Protocol") -Force | Out-Null
            New-ItemProperty -path $registryPath  -Name 'URL Protocol' -PropertyType String -Force | Out-Null
            New-ItemProperty -path $registryPath  -Name 'EditFlags' -Value 41000100 -PropertyType dword -Force | Out-Null
            New-Item ($registryPath +'\shell\open\command') -Force | New-ItemProperty -Name '(default)' -PropertyType String -Value $ProceedAction -Force  | Out-Null
        }else{
            Write-Error "Administrative Rights needed!"
            exit 
        }
    }
}

Function CreateShortcuts($shortCutPath, $TargetPath, $Parameters){
    $WshShell = New-Object -comObject WScript.Shell
    
    $shortcutFilePath = $shortCutPath+"\Shortcut_BackUp.lnk"
    if(-Not (Test-Path -Path $shortcutFilePath )){
        $Shortcut2 = $WshShell.CreateShortcut($shortcutFilePath)
        $Shortcut2.TargetPath = $TargetPath
        $Shortcut2.Arguments = ($Parameters.Replace("%1", "backupperscript:BackUp"))
        $Shortcut2.Save()
    }
    
    $shortcutFilePath = $shortCutPath+"\Shortcut_DryRun.lnk"
    if(-Not (Test-Path -Path $shortcutFilePath )){
        $Shortcut = $WshShell.CreateShortcut($shortcutFilePath)
        $Shortcut.TargetPath = $TargetPath
        $Shortcut.Arguments = ($Parameters.Replace("%1", "backupperscript:DryRun"))
        $Shortcut.Save()    
    }
}

function GetFriendlySize($BytesParam) {
$Bytes = [math]::Abs($BytesParam);
    if ($Bytes -ge 1GB)
    {
        $Value = '{0:F2} GB' -f ($Bytes / 1GB)
    }
    elseif ($Bytes -ge 1MB)
    {
        $Value = '{0:F2} MB' -f ($Bytes / 1MB)
    }
    elseif ($Bytes -ge 1KB)
    {
        $Value = '{0:F2} KB' -f ($Bytes / 1KB)
    }
    else
    {
        $Value = '{0} bytes' -f $Bytes
    }
    if($BytesParam -ne $Bytes){
        $Value = '-'+$Value;
    }
    return $Value;
}

Function SplitURL(){
    if($URL.Length -gt 0){
        $InvokedFromURL = $true
        $fullURL = $URL.Split(':');
        if($fullURL[1].Length -gt 0){
            $params = $fullURL[1].Split('/');
            foreach($param in $params){
                $keyvalue = $param.Split('=');
                Write-Host ("Param: "+$keyvalue[0]+"="+$keyvalue[1])
            }
        }
    }
}

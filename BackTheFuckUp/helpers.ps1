﻿function AddRegistryEntries($protocolName, $ProceedAction){
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
    
    $Shortcut2 = $WshShell.CreateShortcut($shortCutPath+"\Shortcut_BackUp.lnk")
    $Shortcut2.TargetPath = $TargetPath
    $Shortcut2.Arguments = ($Parameters.Replace("%1", "backupperscript:BackUp"))
    $Shortcut2.Save()

    $Shortcut = $WshShell.CreateShortcut($shortCutPath+"\Shortcut_DryRun.lnk")
    $Shortcut.TargetPath = $TargetPath
    $Shortcut.Arguments = ($Parameters.Replace("%1", "backupperscript:DryRun"))
    $Shortcut.Save()    
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

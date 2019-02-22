
#include scripts
. ($PSScriptRoot+'\LogBook.ps1')
#end include scripts

function doLog{
    Param(
      [string]$entry,
      [LogBookType]$Type = [LogBookType]::Log
    )
    
    if ($script:LogBook -eq $null) { [LogBook]$script:LogBook = [LogBook]::new(); }    
    $script:LogBook.doLog($entry, $Type);

}

function LogBook_TabIn([int]$num = 1){
    if ($script:LogBook -eq $null) { [LogBook]$script:LogBook = [LogBook]::new(); }    
    $script:LogBook.TabIn($num);
}
function LogBook_TabOut([int]$num = 1){
    if ($script:LogBook -eq $null) { [LogBook]$script:LogBook = [LogBook]::new(); }        
    $script:LogBook.TabOut($num);
}


function AddRegistryEntries($protocolName, $ProceedAction){
    $registryPath = 'Registry::HKEY_CLASSES_ROOT\'+$protocolName
    
    if(-Not (Test-Path -Path $registryPath )){
        doLog -entry ("Add Registry key") 
        LogBook_TabIn;
        $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
        if($currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)){
            doLog -entry ("Add Registry key and entry  ($registryPath) (default)='"+("URL:"+$protocolName+" Protocol")+"' ") -Type Detail
            New-Item $registryPath  -Force | New-ItemProperty -Name '(default)' -PropertyType String -Value ("URL:"+$protocolName+" Protocol") -Force | Out-Null
            doLog -entry ("Add Registry entry URL Protocol=''") -Type Detail
            New-ItemProperty -path $registryPath  -Name 'URL Protocol' -PropertyType String -Force | Out-Null
            doLog -entry ("Add Registry entry EditFlags='41000100'") -Type Detail
            New-ItemProperty -path $registryPath  -Name 'EditFlags' -Value 41000100 -PropertyType dword -Force | Out-Null
            doLog -entry ("Add Registry key and entry ($registryPath\shell\open\command') (default)='"+$ProceedAction+"'") -Type Detail
            New-Item ($registryPath +'\shell\open\command') -Force | New-ItemProperty -Name '(default)' -PropertyType String -Value $ProceedAction -Force  | Out-Null
            doLog -entry ("Registry entries added to ($registryPath)") -Type Success
        }else{
            doLog -entry ("{%ADMIN_RIGHTS_NEEDED%}") -Type Exception
        }
        LogBook_TabOut;
    }else{    
        doLog -entry ("Registry key Found ($registryPath)") -Type Detail
    }
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

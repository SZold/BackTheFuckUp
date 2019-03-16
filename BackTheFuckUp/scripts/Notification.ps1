class ProgressBar{
<#
[Y] Yes [A] Yes to All [H] Halt Command [S] Suspend [?] Help (default is "Y"):


$ProgressBar = New-BTProgressBar -Status 'Getting User Objects' -Value 0.26 
$ProgressBar2 = New-BTProgressBar -Status 'Getting User Objects2' -Value 0.80

New-BurntToastNotification –Text ‘IdentityNow Source Import’ -ProgressBar $ProgressBar, $ProgressBar2 –UniqueIdentifier 'Get Users' 

        
        $ProgressBar = New-BTProgressBar -Status ('Backing up "'+$this.SourcePath+'"') -Indeterminate
        New-BurntToastNotification –Text (‘Backing up from "'+$this.SourcePath+'"’) -ProgressBar $ProgressBar –UniqueIdentifier 'sajt' 
        sleep(5)
            $ProgressBar = New-BTProgressBar -Status ('Backing up "'+$File.name+'"') -Value ($i / $Files.length) -ValueDisplay ($i +'/' +$Files.length)
            New-BurntToastNotification –Text (‘Backing up from "'+$this.SourcePath+'"’) -ProgressBar $ProgressBar –UniqueIdentifier 'sajt' -Silent 
            sleep(0.5)
            #>
}
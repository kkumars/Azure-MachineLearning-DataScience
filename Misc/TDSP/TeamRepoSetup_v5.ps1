﻿$role = Read-Host -Prompt 'Select your role in your team:1-team lead;[2]-project lead;3-project team member'

if ((!$role) -or (!($role -eq 1) -and !($role -eq 3))){
    $role = 2
}

$rootdir = $PWD.Path

$server = $null
$gcminstalled = $false

$name1 = 'data science project template repository'
$name2 = 'team project template repository'
$name3 = 'project repository'
$name4 = 'data science common utilities repository'
$name5 = 'team utilities repository'

#if ($role -eq 3){
#    $name1 = 'team repository'
#    $name2 = 'project repository'
#    $name3 = 'your team utilities repository'
#} elseif ($role -eq 1){
#    $name1 = 'data science project template repository'
#    $name2 = 'your team repository'
#    $name3 = 'data science common utilities repository'
#    $name4 = 'your team utilties repository'
#} else{
#    $role = 2
#    $name1 = 'team repository'
#    $name2 = 'project repository'
#}

# set up the team/project, or clone the project repository
if ($role -eq 1)
{
    $vstsyesorno = Read-Host -Prompt 'Do you want to set up your team repository on Visual Studio Team Services (VSTS)?[Y]/N'
    $nameofrole = $name1
} ElseIf ($role -eq 2)
{
    $vstsyesorno = Read-Host -Prompt 'Do you want to set up your project repository on Visual Studio Team Services (VSTS)?[Y]/N'
    $nameofrole = $name2
}
else{
    $vstsyesorno = Read-Host -Prompt 'Do you want to clone your project repository on your machine?[Y]/N'
    $nameofrole = $name3
}

function copyFiles($rootdir, $reponame1, $reponame2, $nameparam1, $nameparam2){
    $SourceDirectory = $rootdir+"\"+$reponame1
    $DestinationDirectory = $rootdir+"\"+$reponame2
    $ExcludeSubDirectory = $SourceDirectory+'\.git'
    $files = Get-ChildItem $SourceDirectory -Recurse | Where-Object { $ExcludeSubDirectory -notcontains $_.DirectoryName }
    $overwriteyesno = 'n'
    $copied = 'n'
    foreach ($file in $files)
    {
        $CopyPath = Join-Path $DestinationDirectory $file.FullName.Substring($SourceDirectory.length)
        if ((Test-Path $CopyPath) -and ($overwriteyesno -eq 'n' -or $overwriteyesno -eq 'y')){
            $promptnote1 = $CopyPath+" exists. Do you want to overwrite?[A]-all/Y-yes/N-no"
            $overwriteyesno = Read-Host -Prompt $promptnote1
            if (!$overwriteyesno -or $overwriteyesno.ToLower() -eq 'a')
            {
                $overwriteyesno = 'a'
            } ElseIf ($overwriteyesno.ToLower() -eq 'y')
            {
                $overwriteyesno = 'y'
            } 
        } else {
            $overwriteyesno = 'a'
        }
        if (($overwriteyesno -eq 'y') -or ($overwriteyesno -eq 'a'))
        {
            Copy-Item $file.FullName -Destination $CopyPath -Force
            $copied = 'y'
        }
    }

    if ($copied = 'y')
    {
        Write-host $nameparam1 "copied to the "$nameparam2" on your disk." -ForegroundColor "Green"
    }
    cd $DestinationDirectory
    write-host 'Files copied'
}

function installGCM
{
    Write-host "Installing Chocolatey. It is needed to install Git Credential Manager." -ForegroundColor "Yellow"
    iwr https://chocolatey.org/install.ps1 -UseBasicParsing | iex
    Write-host "Chocolatey installed." -ForegroundColor "Green"

    Write-host "Installing Git Credential Manager..." -ForegroundColor "Yellow"
    choco install git-credential-manager-for-windows -y
    Write-host "Git Credential manager installed." -ForegroundColor "Green"
}

function gitClone($url, $nameofrole)
{
    Write-host "Start cloning the"$nameofrole"..." -ForegroundColor "Yellow"
    Write-host "You might be asked to input your credentials..." -ForegroundColor "Yellow"
    git clone $url
    Write-host $nameofrole" cloned." -ForegroundColor "Green"
}

if (!$vstsyesorno -or $vstsyesorno.ToLower() -eq 'y')
{
    $server = Read-Host -Prompt 'Please input your VSTS server name'
    
    if ($role -eq 1)
    {
        $prompt1 = 'Input the name of the '+$name1
        $prompt2 = 'Input the name of the '+$name2
    } Else
    {
        $prompt1 = 'Input the name of the '+$name2
        $prompt2 = 'Input the name of the '+$name3
    } 
    $generalreponame = Read-Host -Prompt $prompt1
    $teamreponame  = Read-Host -Prompt $prompt2
    $generalreponame = [uri]::EscapeDataString($generalreponame)
    $teamreponame = [uri]::EscapeDataString($teamreponame)
    $generalrepourl = 'https://'+$server+'.visualstudio.com/_git/'+$generalreponame
    if ($role -eq 1)
    {
        $teamrepourl = 'https://'+$server+'.visualstudio.com/_git/'+$teamreponame
    } ElseIf ($role -eq 2)
    {
        $teamrepourl = 'https://'+$server+'.visualstudio.com/'+$generalreponame+'/_git/'+$teamreponame
    } else{
        $generalrepourl = 'https://'+$server+'.visualstudio.com/'+$generalreponame+'/_git/'+$teamreponame
    }
    if ($role -eq 1)
    {
        Write-host "URL of the "$name1 "is "$generalrepourl -ForegroundColor "Yellow"
        Write-host "URL of the "$name2 "is "$teamrepourl -ForegroundColor "Yellow"
    } ElseIf ($role -eq 2)
    {
        Write-host "URL of the "$name2 "is "$generalrepourl -ForegroundColor "Yellow"
        Write-host "URL of the "$name3 "is "$teamrepourl -ForegroundColor "Yellow"
    }
    else{
        Write-host "URL of the "$name3 "is "$generalrepourl -ForegroundColor "Yellow"
    }
    
    $ClonePath = Join-Path $rootdir $generalreponame

    if (Test-Path $ClonePath)
    {
        $prompt1 = $ClonePath+' already exists. It looks like you have cloned it before. [P]-pull to update/S-skip?'
        $cloneagainyesno = Read-Host $prompt1
        if (!($cloneagainyesno.ToLower() -eq 's'))
        {
            
            Write-Host 'running git pull to update the existing repository '$generalrepourl -ForegroundColor Yellow
            cd $ClonePath
            git pull
            Write-Host $name1 " updated." -ForegroundColor Green 
            cd $rootdir
        }
    } else{
        Write-Host 'Clone '$generalrepourl '...' -ForegroundColor Yellow

        installGCM
        $gcminstalled = $true

        gitClone $generalrepourl $nameofrole
    }

    if ($role -lt 3)
    {
        $ClonePath = Join-Path $rootdir $teamreponame
        if (Test-Path $ClonePath)
        {
            $prompt1 = $ClonePath+' already exists. It looks like you have cloned it before. [P]-pull to update/S-skip?'
            $cloneagainyesno = Read-Host $prompt1
            if (!($cloneagainyesno.ToLower() -eq 's'))
            {
                Write-Host 'running git pull to update the existing repository '$teamrepourl -ForegroundColor Yellow
                cd $ClonePath
                git pull
                Write-Host $nametouse " updated." -ForegroundColor Green 
                cd $rootdir
            }
        } else{
            Write-Host 'Clone '$teamrepourl '...' -ForegroundColor Yellow
            if (!$gcminstalled)
            {
                installGCM
                $gcminstalled = $true
            }

            gitClone $teamrepourl $nametouse
        }
        
        Write-host "Copying the entire directory in"$rootdir"\"$generalreponame "except .git directory to"$rootdir"\"$teamreponame"..." -ForegroundColor "Yellow"
        #$SourceDirectory = $rootdir+"\"+$generalreponame
        $DestinationDirectory = $rootdir+"\"+$teamreponame
        #$ExcludeSubDirectory = $SourceDirectory+'\.git'
        #$files = Get-ChildItem $SourceDirectory -Recurse | Where-Object { $ExcludeSubDirectory -notcontains $_.DirectoryName }
        #$promptnote = 'n'
        #$copied = 'n'
        #foreach ($file in $files)
        #{
        #    $CopyPath = Join-Path $DestinationDirectory $file.FullName.Substring($SourceDirectory.length)
        #    if ((Test-Path $CopyPath) -and ($promptnote -eq 'n' -or $promptnote -eq 'y')){
        #        $promptnote1 = $CopyPath+" exists. Do you want to overwrite?[A]-all/Y-yes/N-no"
        #        $overwriteyesno = Read-Host -Prompt $promptnote1
        #        if (!$overwriteyesno -or $overwriteyesno.ToLower() -eq 'a')
        #        {
        #            $overwriteyesno = 'a'
        #        } ElseIf ($overwriteyesno.ToLower() -eq 'y')
        #        {
        #            $overwriteyesno = 'y'
        #        } 
        #    } else {
        #        $overwriteyesno = 'y'
        #    }
        #    if (($overwriteyesno -eq 'y') -or ($overwriteyesno -eq 'a'))
        #    {
        #        Copy-Item $file.FullName -Destination $CopyPath -Force
        #        $copied = 'y'
        #    }
        #}

        #if ($copied = 'y')
        #{
        #    Write-host $name1 "copied to the "$name2" on your disk." -ForegroundColor "Green"
        #}
        if ($role -eq 1) {
            copyFiles $rootdir $generalreponame $teamreponame $name1 $name2
            Write-host "Change to the "$name2 "directory "$DestinationDirectory -ForegroundColor "Green"
        } else{
            copyFiles $rootdir $generalreponame $teamreponame $name2 $name3
            Write-host "Change to the "$name3 "directory "$DestinationDirectory -ForegroundColor "Green"
        }
        
        
        if ($role -eq 1)
        {
            $prompt = 'If you are ready to commit the '+$name2+', enter Y. Otherwise, go to change your '+$name2+' and come back to enter Y to commit...'
        } else
        {
            $prompt = 'If you are ready to commit the '+$name3+', enter Y. Otherwise, go to change your '+$name2+' and come back to enter Y to commit...'
        }
        $commitornot = Read-Host -Prompt $prompt

        if ($commitornot.ToLower() -eq 'y')
        {
            git add .
            $username = git config user.name
            $email = git config user.email
            if (!$username)
            {
                $user = Read-Host -Prompt 'For logging purpose, input your name'
                git config --global user.name $user
            }
            if (!$email)
            {
                $useremail = Read-Host -Prompt 'Fog logging purpose, input your email address'
                git config --global user.email $useremail
            }
            git commit -m"changed the team repository directory."
            git push
        } else {
            Write-host "I do not understand your input. Please commit later by yourself using the following commands in sequence." -ForegroundColor "Yellow"
            Write-host "These commands need to be submitted when you are in "$DestinationDirectory
            Write-host "git add ." -ForegroundColor "Green"
            Write-host "git config --global user.name john.smith" -ForegroundColor "Green"
            Write-host "git config --global user.email johnsmith@example.com" -ForegroundColor "Green"
            Write-host "git commit -m'This is a commit note'" -ForegroundColor "Green"
            Write-host "git push" -ForegroundColor "Green"
        }
    }
}



# Set up the team common utility repository, or clone the team common utility repository.
if ($role -eq 1)
{
    $teamutilityyesorno = Read-Host -Prompt 'Do you want to set up your team utilities repository on Visual Studio Team Services (VSTS)?[Y]/N'
} ElseIf ($role -eq 3)
{
    $teamutilityyesorno = Read-Host -Prompt 'Do you want to clone your team utilities repository on Visual Studio Team Services (VSTS) to your local machine?[Y]/N'
}

if (!($role -eq 2)) # if it is team lead or project individual contributor, set up or clone the team utility repository
{ 
    cd $rootdir

    if (!$teamutilityyesorno -or $teamutilityyesorno.ToLower() -eq 'y')
    {
        $teamreponewinput = $false
        if (!$server)
        {
            Write-host "Installing Chocolatey. It is needed to install Git Credential Manager." -ForegroundColor "Yellow"
            iwr https://chocolatey.org/install.ps1 -UseBasicParsing | iex
            Write-host "Chocolatey installed." -ForegroundColor "Green"

            Write-host "Installing Git Credential Manager..." -ForegroundColor "Yellow"
            choco install git-credential-manager-for-windows -y
            Write-host "Git Credential manager installed." -ForegroundColor "Green"

            $server = Read-Host -Prompt 'Please input your VSTS server name'
            $prompt1 = 'Input the name of the '+$name2 # team repo name is needed since the team utility repo is under the team repo
            $teamreponame  = Read-Host -Prompt $prompt1
            $teamreponame = [uri]::EscapeDataString($teamreponame)
            $teamreponewinput = $true
        }
        $prompt2 = 'Input the name of the '+$name5 #the name of the team utility repo
        $teamutilreponame  = Read-Host -Prompt $prompt2
        $teamutilreponame = [uri]::EscapeDataString($teamutilreponame)
        if (!$teamreponewinput)
        {
            if ($role -eq 1)
            {
                $teamutilrepourl = 'https://'+$server+'.visualstudio.com/'+$teamreponame+'/_git/'+$teamutilreponame
            } else
            {
                $teamutilrepourl = 'https://'+$server+'.visualstudio.com/'+$generalreponame+'/_git/'+$teamutilreponame
            }
        } else{
            $teamutilrepourl = 'https://'+$server+'.visualstudio.com/'+$teamreponame+'/_git/'+$teamutilreponame
        }
        
        if ($role -eq 1)
        {
            $prompt1 = 'Please input the name of the '+$name4 #for team lead, he needs to know the common utility repo in order to set up the utility repo of his own team
            $commonutilreponame = Read-Host -Prompt $prompt1
            $commonutilreponame = [uri]::EscapeDataString($commonutilreponame)
            $commonutilrepourl = 'https://'+$server+'.visualstudio.com/_git/'+$commonutilreponame
        
            Write-host "URL of the "$name4 "is "$commonutilrepourl -ForegroundColor "Yellow"
            Write-host "URL of the "$name5 "is "$teamutilrepourl -ForegroundColor "Yellow"
        } else{
            Write-host "URL of the "$name5 "is "$teamutilrepourl -ForegroundColor "Yellow"
        }
    
        
        if ($role -eq 1)
        {
            $ClonePath = Join-Path $rootdir $commonutilreponame

            if (Test-Path $ClonePath)
            {
                $prompt1 = $ClonePath+' already exists. It looks like you have cloned it before. [P]-pull to update/S-skip?'
                $cloneagainyesno = Read-Host $prompt1
                if (!($cloneagainyesno.ToLower() -eq 's'))
                {
                    Write-Host 'running git pull to update the existing repository '$commonutilrepourl -ForegroundColor Yellow
                    cd $ClonePath
                    git pull
                    Write-Host $name4 "updated." -ForegroundColor Green 
                    cd $rootdir
                }
            } else{
                Write-Host 'Clone '$commonutilrepourl ' ...' -ForegroundColor Yellow
                if (!$gcminstalled)
                { 
                    installGCM
                    $gcminstalled = $true
                }
                Write-host "You might be asked to input your credentials..." -ForegroundColor "Yellow"
                git clone $commonutilrepourl
                Write-host $name4" cloned." -ForegroundColor "Green"
            }
            $ClonePath = Join-Path $rootdir $teamutilreponame
            if (Test-Path $ClonePath)
            {
                $prompt1 = $ClonePath+' already exists. It looks like you have cloned it before. [P]-pull to update/S-skip?'
                $cloneagainyesno = Read-Host $prompt1
                if (!($cloneagainyesno.ToLower() -eq 's'))
                {
                    Write-Host 'running git pull to update the existing repository '$commonutilrepourl -ForegroundColor Yellow
                    cd $ClonePath
                    git pull
                    Write-Host $name5 "updated." -ForegroundColor Green 
                    cd $rootdir
                }
            } else
            {
                Write-host "Start cloning"$name5"..." -ForegroundColor "Yellow"
                Write-host "Currently it is empty. You need to determine the content of it..." -ForegroundColor "Yellow"
                git clone $teamutilrepourl
                Write-host $name5 "cloned." -ForegroundColor "Green"
            }
        
            #Write-host "Copying the entire directory in"$rootdir"\"$commonutilreponame "except .git directory to"$rootdir"\"$teamutilreponame"..." -ForegroundColor "Yellow"
            #copyFiles $rootdir $commonutilreponame $teamutilreponame $name4 $name5
            #$DestinationDirectory = $rootdir+"\"+$teamutilreponame
            #Write-host "Change to the "$name5 "directory "$DestinationDirectory -ForegroundColor "Green"
            
            #cd $DestinationDirectory

            #$prompt = 'If you are ready to commit the '+$name5+', enter Y. Otherwise, go to change your '+$name5+' and come back to enter Y to commit...'
            #$commitornot = Read-Host -Prompt $prompt

            #if ($commitornot.ToLower() -eq 'y')
            #{
            #    git add .
            #    $username = git config user.name
            #    $email = git config user.email
            #    if (!$username)
            #    {
            #        $user = Read-Host -Prompt 'For logging purpose, input your name'
            #        git config --global user.name $user
            #    }
            #    if (!$email)
            #    {
            #        $useremail = Read-Host -Prompt 'Fog logging purpose, input your email address'
            #        git config --global user.email $useremail
            #    }
            #    git commit -m"changed the team repository directory."
            #    git push
            #} else {
            #    Write-host "I do not understand your input. Please commit later by yourself using the following commands in sequence." -ForegroundColor "Yellow"
            #    Write-host "These commands need to be submitted when you are in "$DestinationDirectory
            #    Write-host "git add ." -ForegroundColor "Green"
            #    Write-host "git config --global user.name john.smith" -ForegroundColor "Green"
            #    Write-host "git config --global user.email johnsmith@example.com" -ForegroundColor "Green"
            #    Write-host "git commit -m'This is a commit note'" -ForegroundColor "Green"
            #    Write-host "git push" -ForegroundColor "Green"
            #}
        } else
        {
            $ClonePath = Join-Path $rootdir $teamutilreponame
            if (Test-Path $ClonePath)
            {
                $prompt1 = $ClonePath+' already exists. It looks like you have cloned it before. [P]-pull to update/S-skip?'
                $cloneagainyesno = Read-Host $prompt1
                if (!($cloneagainyesno.ToLower() -eq 's'))
                {
                    Write-Host 'running git pull to update the existing repository '$teamutilrepourl -ForegroundColor Yellow
                    cd $ClonePath
                    git pull
                    Write-Host $name5 "updated." -ForegroundColor Green 
                    cd $rootdir
                }
            } else{
                Write-host "Start cloning the"$name5"..." -ForegroundColor "Yellow"
                if (!$gcminstalled)
                {
                    installGCM
                    $gcminstalled = $true
                }
                Write-host "You might be asked to input your credentials..." -ForegroundColor "Yellow"
                git clone $teamutilrepourl
                Write-host $name5" cloned." -ForegroundColor "Green"
            }
        }
    }
}



function printarray($arrayname)
{
    $rowcount = 0
    foreach($name in $arrayname)
    {
        $rowcount = $rowcount + 1
        $echostring = '['+$rowcount+']: '+$name
        echo $echostring
    }
}

# Authenticate to Azure.
if ($role -lt 3){
    if ($role -eq 1){
        $prompt = "Do you want to create an Azure file share service for your team? [Y]/N"
    }
    else {
        $prompt = "Do you want to create an Azure file share service for your project? [Y]/N"
    }
    $createornot = Read-Host -Prompt $prompt
    if (!$createornot -or ($createornot.ToLower() -eq 'y')){
        Write-Host "Getting the list of subscriptions..." -ForegroundColor Yellow
        try
        {
            $sublist = Get-AzureRmSubscription
        } 
        Catch
        {
            Write-Host "Login to Azure..." -ForegroundColor Yellow
            Login-AzureRmAccount
            $sublist = Get-AzureRmSubscription
        }
        
        $subnamelist = $sublist.SubscriptionName
        #$subnamecount = 0
        #foreach($subname in $subnamelist)
        #{
        #    $subnamecount = $subnamecount + 1
        #    $echostring = '['+$subnamecount+']: '+$subname
        #    echo $echostring
        #}
        printarray $subnamelist

        # Select your subscription
        $subnameright = $false
        $quitornot = $false
        DO
        {
            $promptstring = 'Enter the index of the subscription name where resources will be created(1-'+$subnamelist.Length+')'
            $subindex = Read-Host $promptstring
            #$index = [array]::indexof($subnamelist,$sub)
    
            if (($subindex -gt 0) -and ($subindex -le $subnamelist.Length)) #selected index is in the range of 1 to the number of subscriptions
            {
                
                $sub = $subnamelist[$subindex-1]
                $prompt1 = "You selected subscription ["+$subindex+"]:"+$sub+". [Y]-yes to continue/N-no to reselect"
                $selectedright = Read-Host $prompt1
                if (!$selectedright -or $selectedright.ToLower() -eq 'y')
                {
                    $subnameright = $true
                }
            }
            if (!$subnameright)
            {
                $quitornotask = Read-Host 'The index of the subscription you selected is out of bounds. [R]-retry/Q-quit'
                if ($quitornotask.ToLower() -eq 'q')
                {
                    Write-Host "Creating Azure file share service quit." -ForegroundColor "Red"
                    $quitornot = $true
                }
            }
        } while(!$subnameright -and !$quitornot)

        if ($subnameright) #subscription name selected correctly
        {
            Write-Host "Getting the list of storage accounts under subscription "$sub -ForegroundColor Yellow
            Get-AzureRmSubscription -SubscriptionName $sub | Select-AzureRmSubscription
            $storageaccountlist = Get-AzureRmStorageAccount #Retrieve the storage account list
            $storageaccountnames = $storageaccountlist.StorageAccountName #get the storage account names
            Write-Host "Here are the storage account names under your subscription "$sub -ForegroundColor Yellow
            #echo $storageaccountnames
            #$sacount = 0
            #foreach($saname in $storageaccountnames)
            #{
            #    $sacount = $sacount + 1
            #    $echostring = '['+$sacount+']: '+$saname
            #    echo $echostring
            #}
            printarray $storageaccountnames

            $resourcegroupnames = $storageaccountlist.ResourceGroupName #get the resource group for storage accounts
            $createornotsa = Read-Host 'Do you want to create a new storage account for your Azure file share?[Y]/N'
            $saretryornot = 'r'
            if (!$createornotsa -or ($createornotsa.ToLower() -eq 'y')){ #create a new storage account
                $havegoodsaname = $false
                $saretry = $true
                $loc = 'southcentralus'
                while(!$havegoodsaname -and $saretry) {
                    $sa0 = Read-Host 'Enter the storage account name to create (only accept lower case letters and numbers)'
                    $sa = $sa0.ToLower()
                    $sa = $sa -replace '[^a-z0-9]'
                    if (!($sa -eq $sa0))
                    {
                        Write-Host "You input storage account name "$sa0 ". To follow the naming convention of Azure storage account names, it is converted to" $sa"." -ForegroundColor Yellow
                    }
                    $index = [array]::indexof($storageaccountnames,$sa)
                    if ($index -ge 0) #storage accont name already exists. 
                    {
                        $rg = $resourcegroupnames[$index]
                        $saretryornot = Read-Host "Storage Account already exists. [R]-retry/U-use/Q-quit"  #storage account already exists. Retry, use it, or quit.
                        if ($saretryornot.ToLower() -eq 'q') #quit
                        {
                            $saretry = $false
                        } ElseIf ($saretryornot.ToLower() -eq 'u')
                        {
                            $prompt1 = "You choose to use an existing storage account ["+($index+1)+"]:"+$sa+". [Y]-continue/R-retry"
                            $useexisting = Read-Host $prompt1
                            if (!$useexisting -or $useexisting.ToLower() -eq 'y')
                            {
                                $havegoodsaname = $true
                                Write-Host "Existing storage account"$sa "will be used. Its resource group is"$rg -ForegroundColor Yellow
                            }
                        }
                        
                    } else{ #storage account does not exist
                        Write-Host "Storage account" $sa "will be created..." -ForegroundColor Yellow
                        Write-Host "You need to select the resource group name under which the storage account will be created." -ForegroundColor Yellow
                        Write-Host "Here is the list of existing resource group names" -ForegroundColor Yellow
                        #echo $resourcegroupnames
                        #$rgcount = 0
                        #foreach($rgname in $resourcegroupnames)
                        #{
                        #    $rgcount = $rgcount + 1
                        #    $echostring = '['+$rgcount+']: '+$rgname
                        #    echo $echostring
                        #}
                        printarray $resourcegroupnames
                        
                        $rgvalid = $false
                        while (!$rgvalid)
                        {
                            $prompt1 = 'Enter the index of resource group name (0-New/1-'+$resourcegroupnames.Length+'-Use existing resource group)'
                            $rg0 = Read-Host $prompt1
                            if ($rg0 -eq 0)
                            {
                                $rg0 = Read-Host 'Please input the name of a new resource group to create(only allows lower case letters, numbers, underline, and hyphen)'
                                $rg = $rg0 -Replace '[^a-zA-Z0-9-_]' #enforce the naming convention
                                if (!($rg -eq $rg0))
                                {
                                    Write-Host "The resource group name you input is "$rg0 ". To follow the naming convention of Azure resource group, it is converted to "$rg
                                }
                                $index = [array]::indexof($resourcegroupnames,$rg)
                                if ($index -ge 0) #resource group exists
                                {
                                    $prompt1 = "Resource group "+$rg+" exists (resource group ["+($index+1)+"]. [U]-use/R-retry"
                                    $useexisting = Read-Host $prompt1
                                    if (!$useexisting -or $useexisting.ToLower() -eq 'u')
                                    {
                                        $rgvalid = $true
                                    }
                                }
                                else
                                {
                                    $rgvalid = $true
                                }
                            }
                            else{
                                if ($rg0 -gt 0 -and $rg0 -le $resourcegroupnames.Length)
                                {
                                    $rg = $resourcegroupnames[$rg0-1]
                                    $prompt1 = "You selected resource group ["+$rg0+"]:"+$rg+". [Y]-continue/R-retry"
                                    $continue = Read-Host $prompt1
                                    if ($continue.ToLower() -eq 'y' -or !$continue)
                                    {
                                        $rgvalid = $true
                                    }
                                }
                                else
                                {
                                    Write-Host 'Selected index of existing resource group output of bounds. Retry...' -ForegroundColor Yellow
                                }
                            }
                        }
                        $havegoodsaname = $true
                        $index = [array]::indexof($resourcegroupnames,$rg)
                        if ($index -ge 0){ #resource group already exists
                            Write-Host "Start creating storage account"$sa "under resource group"$rg "at"$loc -ForegroundColor Yellow
                            New-AzureRmStorageAccount -Name $sa -ResourceGroupName $rg -Location $loc -Type 'Standard_LRS' #create a new storage account under rg
                        } else{
                            Write-Host "Start creating resource group"$rg "at"$loc -ForegroundColor Yellow
                            New-AzureRmResourceGroup -Name $rg -Location $loc
                            Write-Host "Start creating storage account"$sa "under resource group"$rg "at"$loc -ForegroundColor Yellow
                            New-AzureRmStorageAccount -Name $sa -ResourceGroupName $rg -Location $loc -Type 'Standard_LRS'
                        }
                    }
                }
                #if ($havegoodsaname -and $saretry) #a good name is provided, $saretryornot is not 'q', and the storage account name does not exist
                #{
                #    $index = [array]::indexof($resourcegroupnames,$rg)
                #    if ($index -ge 0){
                #        Write-Host "Using the existing resource group "$rg -ForegroundColor Yellow
                #    } else{
                #        
                #        Write-Host "Resource group "$rg "does not exist. Creating..." -ForegroundColor Yellow
                #        New-AzureRmResourceGroup -Name $rg -Location $loc
                #    }
                #    if (!($saretryornot.ToLower() -eq 'u')) #not using the existing storage account
                #    {
                #        Write-Host "Start creating storage account "$sa "under resource group "$rg "at "$loc -ForegroundColor Yellow
                #        New-AzureRmStorageAccount -Name $sa -ResourceGroupName $rg -Location $loc -Type 'Standard_LRS'
                #    }
                #}            
            } else{ #use an existing storage account
                $validexistingsasaname = $false
                $saretry = $true
                while(!$validexistingsasaname -and $saretry) {
                    $prompt1 = 'Enter the index of the storage account to use(1-'+$storageaccountnames.Length+')'
                    $saindex = Read-Host $prompt1
                    if ($saindex -gt 0 -and $saindex -le $storageaccountnames.Length) #storage accont name already exists. 
                    {
                        $sa = $storageaccountnames[$saindex-1]
                        $rg = $resourcegroupnames[$saindex-1]
                        $prompt1 = "You selected storage account ["+$saindex+"]:"+$sa+".[Y]-continue/N-reselect"
                        $saconfirm = Read-Host $prompt1
                        if (!$saconfirm -or $saconfirm.ToLower() -eq 'y')
                        {
                            Write-Host "Storage Account"$sa "is selected. Its resource group is"$rg -ForegroundColor Yellow  #storage account exists. 
                            $validexistingsasaname = $true
                        }
                    } else{
                        $saretryornot = Read-Host "Selected index of storage account out of bounds. [R]-retry/Q-quit"
                        if ($saretryornot.ToLower() -eq 'q')
                        {
                            $saretry = $false
                            Write-Host "Quitting... " -ForegroundColor Yellow
                        }
                    }
                }
            }
            
            Set-AzureRmCurrentStorageAccount -ResourceGroupName $rg -StorageAccountName $sa

            # Create a Azure File Service Share
            $validsharename = $false
            $quitcreateshare = $false
            while (!$validsharename -and !$quitcreateshare)
            {
                $sharename0 = Read-Host 'Enter the name of the file share service to create (lower case characters, numbers, and - are accepted)'
                if (!$sharename0)
                {
                    $retrysharename = Read-Host 'You entered an empty file share name. [R]-retry/Q-quit'
                    if ($retrysharename.ToLower() -eq 'q')
                    {
                        $quitcreateshare = $true
                    }
                }
                else
                {
                    $sharename = $sharename0.ToLower()
                    $sharename = $sharename -Replace '[^a-z0-9-]'
                    if (!($sharename -eq $sharename0))
                    {
                        Write-Host "Invalid file share name "$sharename0 " converted to "$sharename -ForegroundColor Yellow
                    }
                    if (!($sharename[0] -match "[a-z0-9]") -or ($sharename -match "--"))
                    {
                        
                        $retrysharename = Read-Host "Invalid file share name. File share name cannot start with non-alphanumeric characters. It cannot have -- either.[R]-retry/Q-quit"
                        if ($retrysharename.ToLower() -eq 'q')
                        {
                            $quitcreateshare = $true
                        }
                    }
                    else
                    {
                        $validsharename = $true
                    }
                }
            }

            if ($validsharename)
            {
                $s = New-AzureStorageShare $sharename
                # Create a directory under the FIle share. You can give it any name
                New-AzureStorageDirectory -Share $s -Path 'data' 
                # List the share to confirm that everything worked
                Get-AzureStorageFile -Share $s
                Write-Host "An Azure file share service created. It can be later mounted to the Azure virtual machines created for your team projects." -ForegroundColor "Green"
                Write-Host "Please keep a note for the information of the Azure file share service. It will be needed in the future when mounting it to Azure virtual machines" -ForegroundColor "Green"
                $outputtofile = Read-Host "Do you want to output the file share information to a file in your current directory?[Y]/N"
                if (!$outputtofile -or ($outputtofile.ToLower() -eq 'y'))
                {
                    $filenameright = $false
                    $skipoutputfile = $false
                    while(!$filenameright -and !$skipoutputfile)
                    {
                        $filename=Read-Host "Please provide the file name. This file under the current working directory will be created to store the file share information."
                        if (!$filename)
                        {
                            Write-Host "File name cannot be empty." -ForegroundColor Yellow
                        }
                        else
                        {
                            $filename=$PWD.Path+'\'+$filename
                            if (Test-Path $filename)
                            {
                                $fileoutput = Read-Host $filename "already exists. [R]-retry/Q-quit"
                                if ($fileoutput.ToLower() -eq 'q')
                                {
                                    $skipoutputfile = $true
                                }
                            }
                            else
                            {
                                $filenameright = $true
                            }
                        }
                    }
                    if ($filenameright)
                    {
                        $now = Get-Date -format "MM/dd/yyyy HH:mm"
                        "Created date time:"+$now >> $filename
                        "Subscription name:"+$sub >> $filename
                        "Storage account name:"+$sa >> $filename
                        "File share name:"+$sharename >> $filename
                        Write-Host "File share information output to"$filename". Share it with your team members who want to mount it to their virtual machines." -ForegroundColor Yellow
                    }
                }

            }
        }
    }
}

function mountfileservices
{
    # Authenticate to Azure.
    
    Write-Host "Start getting the list of subscriptions under your Azure account..." -ForegroundColor Yellow
    Try
    {
        $sublist = Get-AzureRmSubscription
    }
    Catch
    {
        Write-Host "You have not logged in yet. Please log in first..." -ForegroundColor Yellow
        Login-AzureRmAccount
        $sublist = Get-AzureRmSubscription
    }
    $subnamelist = $sublist.SubscriptionName
    Write-Host "Here are the subscription names under your Azure account:" -ForegroundColor Yellow
    printarray $subnamelist
    # Select your subscription
    $inputfileyesorno = Read-Host "Do you have a file with the information of the file share you want to mount?[Y]-yes/N-no"
    if (!($inputfileyesorno.ToLower() -eq 'n'))
    {
        $inputfileyesorno = 'y'
    }
    $sub = 'NA'
    $sa = 'NA'
    $sharename = 'NA'
    if (!$inputfileyesorno -or ($inputfileyesorno.ToLower() -eq 'y'))
    {
        $inputfilequit = $false
        $inputfileright = $false
        while (!$inputfilequit -and !$inputfileright)
        {
            $filename = Read-Host "Please provide the name of the file with the information of the file share you want to mount"
            if (!$filename)
            {
                $retryinput = Read-Host "File name cannot be empty. [R]-retry/S-skip"
                if ($retryinput.ToLower() -eq 's')
                {
                    $inputfilequit = $true
                }
            }
            else
            {
                if (!(Test-Path $filename))
                {
                    $retryinput = Read-Host "File does not exit. [R]-retry/S-skip"
                    if ($retryinput.ToLower() -eq 's')
                    {
                        $inputfilequit = $true
                    }
                }
                else
                {
                    $inputfileright = $true
                }
            }
        }
        if ($inputfileright)
        {
            $filecontent = Get-Content $filename
            foreach ($line in $filecontent)
            {
                $fields = $line.Split(":")
                switch($fields[0])
                {
                    "Subscription name" {$sub = $fields[1]}
                    "Storage account name" {$sa = $fields[1]}
                    "File share name" {$sharename = $fields[1]}
                }
            }
            if (($sub -eq 'NA') -or ($sa -eq 'NA') -or ($sharename -eq 'NA'))
            {
                Write-Host 'Information about the file share to be mounted is incomplete. You have to manually input information later.' -ForegroundColor Yellow
                $sub = 'NA'
                $sa = 'NA'
                $sharename = 'NA'
            }
        }
    }
        

    $subnameright = $false
    $quitornot = $false
    
    DO
    {
        if ($sub -eq 'NA')
        {
            $sub = Read-Host 'Enter the subscription name where the Azure file share service has been created'
        }
        $index = [array]::indexof($subnamelist,$sub)
        if ($index -ge 0)
        {
            $subnameright = $true
        } else
        {
            $quitornotask = Read-Host 'The subscription name you input does not exist. [R]-retry/Q-quit'
            $sub = 'NA'
            $sa = 'NA'
            $sharename = 'NA'
            if ($quitornotask.ToLower() -eq 'q')
            {
                Write-Host "Mounting Azure file share service quit." -ForegroundColor "Red"
                $quitornot = $true
            }
        }
    } while(!$subnameright -and !$quitornot)
    
    if ($subnameright){
        $retrycount = 0
        $getstoragesucceed = $false
        Get-AzureRmSubscription -SubscriptionName $sub | Select-AzureRmSubscription
        Write-Host "Start getting the list of storage accounts under your subscription "$sub -ForegroundColor Yellow
        while (!$getstoragesucceed -and ($retrycount -lt 10))
        {
            $storageaccountlist = Get-AzureRmStorageAccount -ErrorAction SilentlyContinue -WarningAction SilentlyContinue #Retrieve the storage account list
            if ($storageaccountlist.Length -gt 0) #if not returning empty
            {
                $getstoragesucceed = $true #succeeded
            }
            if (!$getstoragesucceed) #if not succeeded, try one more time
            {
                $retrycount = $retrycount + 1
                Write-Host "Trial "$retrycount" failed to get storage account list from your subscription "$sub". Wait for 1 second to try again."
                Start-sleep -s 1
            }
        }
        if (!$getstoragesucceed -and ($retrycount -eq 10))
        {
            Write-Host "It has failed 10 times getting the storage account. Retry sometime later." -ForegroundColor Red
        }
        else
        {
            $storageaccountnames = $storageaccountlist.StorageAccountName #get the storage account names
            $resourcegroupnames = $storageaccountlist.ResourceGroupName #get the resource group for storage accounts
            Write-Host "Here are the storage account names under subsription "$sub
            printarray $storageaccountnames
            $goodsaname = $false
            $quitornot = $false
            while (!$goodsaname -and !$quitornot)
            {
                if ($sa -eq 'NA')
                {
                    $prompt1 = "Enter the index of the storage account name where your Azure file share you want to mount is created (1-"+$storageaccountnames.Length+")"
                    $saindex = Read-Host $prompt1
                    if ($saindex -gt 0 -and $saindex -le $storageaccountnames.Length)
                    {
                        $sa = $storageaccountnames[$saindex-1]
                        $rg = $resourcegroupnames[$saindex-1]
                        $goodsaname = $true
                    }
                    else
                    {
                        $prompt1 = "Index out of bounds (1-"+$storageaccountnames.Length+").[R]-retry/Q-quit"
                        $quitsa = Read-Host $prompt1
                        if ($quitsa.ToLower() -eq 'q')
                        {
                            $quitornot = $true
                        }
                    }
                } 
                else{
                    $saindex = [array]::IndexOf($storageaccountnames,$sa)
                    if ($saindex -lt 0)
                    {
                        Write-Host "Storage account name"$sa" from the file does not exist. Please manually input it next." -ForegroundColor Yellow
                        $sa = 'NA'
                        $sharename = 'NA'
                    }
                    else
                    {
                        $rg = $resourcegroupnames[$saindex]
                        $goodsaname = $true
                    }
                }
            }
            if ($goodsaname){
                $sharenameexist = $false
                $quitnewsharename = $false
                $storKey = (Get-AzureRmStorageAccountKey -Name $sa -ResourceGroupName $rg ).Key1
                $sharenameright = $false
                $quitornot = $false
                while ((!$sharenameexist) -and (!$quitnewsharename))
                {
                    while(!$sharenameright -and !$quitornot)
                    {
                        if ($sharename -eq 'NA')
                        {
                            $sharename = Read-Host 'Enter the name of the file share to mount (lower case only)'
                            $sharename = $sharename.ToLower()
                        }
                        if (!$sharename)
                        {
                            $quitornotanswer = Read-Host "File share name cannot be empty. [R]-retry/Q-quit"
                            if ($quitornotanswer.ToLower = 'q')
                            {
                                $quitornot = $true
                            }
                        } 
                        else
                        {
                            $sharenameright = $true
                        }
                    }
                    if ($sharenameright)
                    {
                        $drivenameright = $false
                        $existingdisks = [System.IO.DriveInfo]::getdrives()
                        $existingdisknames = $existingdisks.Name
                        Write-Host "Existing disk names are:" -ForegroundColor Yellow
                        printarray $existingdisknames
                        $quitdrivename = $false
                        while (!$drivenameright -and !$quitdrivename)
                        {
                            $drivename = Read-Host 'Enter the name of the drive to be added to your virtual machine. This name should be different from the disk names your virtual machine has.'
                            if (!($drivename[$drivename.Length-1] -eq ':')){
                                $drivename = $drivename+':'
                            }
                            $drivename1 = $drivename+"\"
                            $diskindex = [array]::IndexOf($existingdisknames, $drivename1)
                            if ($diskindex -ge 0)
                            {
                                $prompt1 = "The disk drive"+$drivename+" you want to mount the file share as already exists. [R]-retry/Q-quit"
                                $inputnewdrive = Read-Host $prompt1
                                if ($inputnewdrive.ToLower() -eq 'q')
                                {
                                    $quitdrivename = $true
                                }
                            }
                            else{
                                $drivenameright = $true
                            }
                        }
                        if ($drivenameright)
                        {

                            Write-Host 'File share '$sharename' will be mounted to your virtual machine as drive' $drivename
                            # Save key securely
                            cmdkey /add:$sa.file.core.windows.net /user:$sa /pass:$storKey

                            # Mount the Azure file share as  drive letter on the VM. 
                            try
                            {
                                net use $drivename \\$sa.file.core.windows.net\$sharename
                                $sharenameexist = $true
                            }
                            Catch
                            {
                                $newsharename = Read-Host "File share "$sharename "does not exist. [R]-retry/Q-quit"
                                if ($newsharename.ToLower() -eq 'q')
                                {
                                    $quitnewsharename = $true
                                    Write-Host "Quit mounting this file share." -ForegroundColor Yellow
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

if ($role -gt 0){
    
    $prompt = "Do you want to mount an Azure file share service to your Azure virtual machine? [Y]-yes/N-no to quit."
    
    $mountornot = Read-Host -Prompt $prompt
    if (!$mountornot -or ($mountornot.ToLower() -eq 'y')){
        
        mountfileservices
        $others = $true
        DO{
            $prompt = "Do you want to mount other Azure file share services? [Y]-yes/N-no to quit."
            $mountornot = Read-Host -Prompt $prompt
            if (!$mountornot -or ($mountornot.ToLower() -eq 'y')){
                mountfileservices
            } else{
                $others = $false
            }
        } while($others)
    }
}

Write-Host "All done. Changing to "$rootdir -ForegroundColor Green
cd $rootdir
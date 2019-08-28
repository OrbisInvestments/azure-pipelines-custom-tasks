Param ()

$workFolder 		= $env:AGENT_WORKFOLDER

$repository 		= $env:BUILD_REPOSITORY_ID
$repositoryType 	= $env:BUILD_REPOSITORY_PROVIDER
$sourceFolder 		= $env:BUILD_REPOSITORY_LOCALPATH

$sharedGitFolderName = "g"
$sharedGitFolderPath = Join-Path $workFolder -ChildPath $sharedGitFolderName
$configFileName 	 = "DedupeGitReposConfig.json"
$configFilePath 	 = Join-Path $sharedGitFolderPath $configFileName
$gitProviders		 = @("TfsGit", "Git", "GitHub")

function Write-Config {
    param (
        $config
    )
	
    if (Test-Path $configFilePath -PathType Leaf) {
        $original = Get-Content $configFilePath | ConvertFrom-Json
        if (!(Compare-Object -ReferenceObject $original -DifferenceObject $config -Property repos)) {
            return
        }
    }

    Write-VstsTaskDebug "Writing configuration to $configFilePath"

    if (!(Test-Path $sharedGitFolderPath -PathType Container)) {
        New-Item -ItemType Directory -Force -Path $sharedGitFolderPath | Out-Null
    }

    $config | ConvertTo-Json | Set-Content $configFilePath
}

if ($repositoryType -in $gitProviders)  {

    if (!(Test-Path $configFilePath -PathType Leaf)) {
        Write-VstsTaskDebug "Creating configuration for this agent"

        $config = [pscustomobject]@{
            description  = "Configuration for Dedupe Git Repositories custom build step";
            lastFolderId = 1;
            repos        = @(
                [pscustomobject]@{
                    repository  = $repository;
                    path        = Join-Path $sharedGitFolderName "1";
                }
            )
        }
    }
    else {
        $config = Get-Content $configFilePath | ConvertFrom-Json
    }

    $repo = $config.repos | Where-Object { $_.repository -eq $repository }

    if (!$repo) {
		Write-VstsTaskDebug "Configuring repository for deduplication"

        $config.lastFolderId++
		
        $repo = [pscustomobject]@{
            repository  = $repository;
            path        = Join-Path $sharedGitFolderName $config.lastFolderId;
        }
        
        $config.repos += $repo
    }
	
    $sharedRepoFullPath = Join-Path $workFolder $repo.path
    $sourceFolderTarget = (Get-Item $sourceFolder | Where-Object { $_.LinkType -eq 'SymbolicLink' }).Target

    if ($sourceFolderTarget -and (Join-Path $sourceFolderTarget "") -eq (Join-Path $sharedRepoFullPath "")) {
        Write-Output "Build already symlinked to deduped repository at $sharedRepoFullPath"
    }
    else {
        Write-Output "Migrating build to using a deduped repository at $sharedRepoFullPath"

        if (!(Test-Path $sharedRepoFullPath)) {
            Write-VstsTaskDebug "Creating shared directory $sharedRepoFullPath for repository"
            New-Item -ItemType Directory -Path $sharedRepoFullPath -Force | Out-Null
			
            Write-VstsTaskDebug "Moving repository to shared directory from $sourceFolder"
            Get-ChildItem $sourceFolder -Force | Move-Item -Destination $sharedRepoFullPath
        }
        else {
            Write-VstsTaskDebug "Repository has already been deduped, removing source folder contents for build at $sourceFolder"
            Remove-Item $sourceFolder\* -Recurse -Force 
        }

        Write-VstsTaskDebug "Symlinking source folder at $sourceFolder to deduped repository location at $sharedRepoFullPath"
        New-Item -ItemType SymbolicLink $sourceFolder -Target $sharedRepoFullPath -Force | Out-Null
    }

    Write-Config $config

    Write-Output 'Done'
}
else {
    Write-Error "Not a Git repository"
}

exit 0
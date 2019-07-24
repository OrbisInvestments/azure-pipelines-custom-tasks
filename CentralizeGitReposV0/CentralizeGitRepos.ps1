Param ()

$collectionId 		= $env:SYSTEM_COLLECTIONID
$teamProject 		= $env:SYSTEM_TEAMPROJECT

$workFolder 		= $env:AGENT_WORKFOLDER

$buildDefinitionId 	= $env:SYSTEM_DEFINITIONID
$repository 		= $env:BUILD_REPOSITORY_NAME
$repositoryType 	= $env:BUILD_REPOSITORY_PROVIDER
$sourceFolder 		= $env:BUILD_REPOSITORY_LOCALPATH

$sharedGitFolderName = "g"
$sharedGitFolderPath = Join-Path $workFolder -ChildPath $sharedGitFolderName
$configFileName 	 = "ShareGitRepoConfig.json"
$configFilePath 	 = Join-Path $sharedGitFolderPath $configFileName

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

if ($repositoryType -eq "TfsGit") {

    if (!(Test-Path $configFilePath -PathType Leaf)) {
        Write-VstsTaskDebug "Creating configuration for this agent"

        $config = [pscustomobject]@{
            description  = "Configuration for Share Git Repository custom build step";
            lastFolderId = 1;
            repos        = @(
                [pscustomobject]@{
                    repository  = $repository;
                    path        = Join-Path $sharedGitFolderName "1";
                    collection  = $collectionId;
                    teamProject = $teamProject;
                }
            )
        }
    }
    else {
        $config = Get-Content $configFilePath | ConvertFrom-Json
    }

    $repo = $config.repos | Where-Object { $_.collection -eq $collectionId -and $_.teamProject -eq $teamProject -and $_.repository -eq $repository }

    if (!$repo) {
		Write-VstsTaskDebug "Configuring repository for sharing"

        $config.lastFolderId++
		
        $repo = [pscustomobject]@{
            repository  = $repository;
            path        = Join-Path $sharedGitFolderName $config.lastFolderId;
            collection  = $collectionId;
            teamProject = $teamProject;
        }
        
        $config.repos += $repo
    }
	
	$sharedRepoFullPath = Join-Path $workFolder $repo.path

    if ((Join-Path $sourceFolder "") -eq (Join-Path $sharedRepoFullPath "")) {
        Write-Output "Build already using shared repository at $sourceFolder"
    }
    else {
        Write-Output "Migrating build to using shared repository at $sharedRepoFullPath"

        if (!(Test-Path $sharedRepoFullPath)) {
            Write-VstsTaskDebug "Creating shared directory $sharedRepoFullPath for repository"
            New-Item -ItemType Directory -Path $sharedRepoFullPath -Force | Out-Null
			
            Write-VstsTaskDebug "Moving repository to shared directory from $sourceFolder"
            Get-ChildItem $sourceFolder -Force | Move-Item -Destination $sharedRepoFullPath
        }
        else {
            Write-VstsTaskDebug "Repository is already shared, removing source folder contents for build at $sourceFolder"
            Remove-Item $sourceFolder\* -Recurse -Force 
        }
		
        $sourceFolderJson = Join-Path $workFolder "\SourceRootMapping\$collectionId\$buildDefinitionId\SourceFolder.json"
        $mappings = (Get-Content $sourceFolderJson) -join "`n" | ConvertFrom-Json

        $mappings.build_sourcesdirectory = $repo.path

        Write-VstsTaskDebug "Updating SourceFolder.json for build at $sourceFolderJson with shared repository location $($repo.path)"
        $mappings | ConvertTo-Json | Set-Content $sourceFolderJson	
    }

    Write-Config $config

    Write-Output 'Done'
}
else {
    Write-Error "Not a Git repository"
}

exit 0
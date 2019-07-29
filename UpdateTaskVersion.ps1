Param()

$branchName   = $env:BUILD_SOURCEBRANCHNAME
$taskJsonPath = '.\DedupeGitReposV0\task.json'

function ConvertTo-SemVer($version){
    $version -match "^(?<major>\d+)(\.(?<minor>\d+))?(\.(?<patch>\d+))?(\-(?<pre>[0-9A-Za-z\-\.]+))?(\+(?<build>[0-9A-Za-z\-\.]+))?$" | Out-Null
    $major = [int]$matches['major']
    $minor = [int]$matches['minor']
    $patch = [int]$matches['patch']
    
    if($null -eq $matches['pre']){$pre = @()}
    else{$pre = $matches['pre'].Split(".")}

    New-Object PSObject -Property @{ 
        Major = $major
        Minor = $minor
        Patch = $patch
        Pre = $pre
        VersionString = $version
        }
}

$taskJson     = Get-Content $taskJsonPath | ConvertFrom-Json
$semVer       = ConvertTo-SemVer $branchName.TrimStart('v')

$taskJson.version.Major = $semVer.Major
$taskJson.version.Minor = $semVer.Minor
$taskJson.version.Patch = $semVer.Patch
$taskJson.preview       = $semVer.Pre.Length -gt 0

$taskJson | ConvertTo-Json -Depth 5 | Set-Content $taskJsonPath
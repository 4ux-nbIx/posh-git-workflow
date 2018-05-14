# TODO: delete branch

[PSCustomObject]$global:PoshGitWorkflow = @{
    PullRequestUrlConfigKey = 'workflow.pullrequesturl';
    ReleaseNameArgumentCompleter = { GetReleaseBranches | Where {NameStartsWith $_ $args[2]} | ForEach-Object { ToBranchCompletionResult $_} };
    FeatureNameArgumentCompleter = { GetFeatureBranches | Where {NameStartsWith $_ $args[2]} | ForEach-Object { ToBranchCompletionResult $_} };
    ReleaseFixNameArgumentCompleter = { GetReleaseFixBranches | Where {NameStartsWith $_ $args[2]} | ForEach-Object { ToBranchCompletionResult $_} };
    LocalFeatureNameArgumentCompleter = { GetFeatureBranches | Where {$_.IsLocal -and (NameStartsWith $_ $args[2])} | ForEach-Object { ToBranchCompletionResult $_} };
    LocalReleaseFixNameArgumentCompleter = { GetReleaseFixBranches | Where {$_.IsLocal -and (NameStartsWith $_ $args[2])} | ForEach-Object { ToBranchCompletionResult $_} };
};

function Sync-GitFork {
    <#
    .SYNOPSIS
    Syncs fork with upstream (original) repository.
    
    .DESCRIPTION
    Fetches changes from upstream, rebases master onto upstream/master, pushes master to origin and prunes stale remote tracking refs.
    #>
    [CmdletBinding(SupportsShouldProcess=$false)]
    Param()

    trap {
        return;
    }

    SyncFork
}

function Get-GitFeature {
    <#
    .SYNOPSIS
    Returns feature branches.

    .LINK
    Get-GitRelease

    .LINK
    Get-GitReleaseFix
    #>
    [CmdletBinding()]
    param ()
    
    trap {
        return;
    }

    GetFeatureBranches | Select Name,ShortRefName,RefName,IsHead;
}

function Get-GitRelease {
    <#
    .SYNOPSIS
    Returns release branches.

    .LINK
    Get-GitReleaseFix

    .LINK
    Get-GitFeature
    #>
    [CmdletBinding()]
    param ()
    
    trap {
        return;
    }

    GetReleaseBranches | Select Name,ShortRefName,RefName,IsHead;
}

function Get-GitReleaseFix {
    <#
    .SYNOPSIS
    Returns release fix branches.

    .LINK
    Get-GitRelease

    .LINK
    Get-GitFeature
    #>
    [CmdletBinding()]
    param ()
    
    trap {
        return;
    }

    GetReleaseFixBranches | Select Name,ShortRefName,RefName,IsHead;
}

function Get-Hotfixes {
    [CmdletBinding()]
    param ()
    
    trap {
        return;
    }

    GethotfixBranches | Select Name,ShortRefName,RefName,IsHead;
}

function New-GitFeature {
    <#
    .SYNOPSIS
    Creates new feature branch.
    
    .DESCRIPTION
    Syncs fork and creates branch with the specified name prefixed with 'feature/' on latest master.
    
    .PARAMETER Name
    Branch name without 'feature/' prefix.
    
    .EXAMPLE
    New-GitFeature cool-stuff

    .LINK
    Sync-GitFork

    .LINK
    New-GitRelease

    .LINK
    New-GitReleaseFix
    #>
    [CmdletBinding(SupportsShouldProcess=$false)]
    param(
        [Parameter(Mandatory=$true, 
                   Position=0, 
                   ParameterSetName="Name",
                   HelpMessage="Branch name")]
        [ValidateNotNullOrEmpty()]
        [string]
        $Name
    )

    trap {
        return;
    }

    SyncFork
    
    ExecuteGitCommand 'git checkout' "-B feature/$Name" '--progress'
}


function New-GitRelease {
    <#
    .SYNOPSIS
    Creates new release branch.
    
    .DESCRIPTION
    Syncs fork, creates branch with the specified name prefixed with 'release/' on latest master, pushes it to upstream and removes local ref.
    
    .PARAMETER Name
    Branch name without 'release/' prefix.
    
    .EXAMPLE
    New-GitRelease v1.1

    .LINK
    Sync-GitFork

    .LINK
    New-GitReleaseFix

    .LINK
    New-GitFeature
    #>
    [CmdletBinding(SupportsShouldProcess=$false)]
    param(
        [Parameter(Mandatory=$true, 
                   Position=0, 
                   HelpMessage="Release name (version)")]
        [ValidateNotNullOrEmpty()]
        [string]
        $Name
    )

    trap {
        return;
    }

    SyncFork
    
    ExecuteGitCommand 'git checkout' "-B release/$Name" '--progress'
    ExecuteGitCommand 'git push' '--set-upstream upstream';
    ExecuteGitCommand 'git checkout' 'master' '--progress'
    ExecuteGitCommand 'git branch' "-D release/$Name";
}


function New-GitReleaseFix {
    <#
    .SYNOPSIS
    Creates new release fix branch.
    
    .DESCRIPTION
    Syncs fork and creates branch with the specified name on top of selected release branch. New branch name is constructed in the following manner: release/release-name/branch-name. Release name is optional if there's only one release branch.
    
    .PARAMETER Name
    Branch name without release branch prefix

    .PARAMETER ReleaseName
    Release branch name without release prefix
    
    .EXAMPLE
    New-GitReleaseFix bug-fix

    .LINK
    Sync-GitFork

    .LINK
    New-GitFeature

    .LINK
    New-GitRelease
    #>
    [CmdletBinding(SupportsShouldProcess=$false)]
    param(
        [Parameter(Mandatory=$true, 
                   Position=0, 
                   HelpMessage="Branch name")]
        [ValidateNotNullOrEmpty()]
        [ArgumentCompleter({ & $PoshGitWorkflow.ReleaseNameArgumentCompleter })]
        [string]
        $Name,
        [Parameter(Mandatory=$false, 
                   Position=1, 
                   HelpMessage="Release branch name")]
        [string]
        $ReleaseName
    )

    SyncFork

    $releaseBranches = @(GetReleaseBranches);

    if ($releaseBranches.Count -eq 0) {
        Write-Error 'No release branches found.'
        return;
    }

    $releaseBranch = $null;
    if ($ReleaseName -eq '') {
        $currentBranch = $releaseBranches | Where {$_.IsHead -eq $True} | Select -First 1;

        if ($currentBranch -ne $null)
        {
            $releaseBranch = $currentBranch;
        }

        if ($releaseBranch -eq $null -and $releaseBranches.Count -eq 1)
        {
            $releaseBranch = $releaseBranches[0];
        }

        if ($releaseBranch -eq $null)
        {
            # TODO: Show prompt
            #$choices = @(
            #    New-Object "System.Management.Automation.Host.ChoiceDescription" "&Apple", "Apple"
            #    New-Object "System.Management.Automation.Host.ChoiceDescription" "&Banana", "Banana"
            #    New-Object "System.Management.Automation.Host.ChoiceDescription" "&Orange", "Orange"
            #)
            #    
            ## Single-choice prompt
            #$host.UI.PromptForChoice("Choose a fruit", "You may choose one", $choices, 1)
            Write-Error 'Please specify release branch name.'
            return;
        }
    }
    else {
        $releaseBranch = $releaseBranches | Where {$_.Name -eq $ReleaseName} | Select -First 1;

        if ($releaseBranch -eq $null) {
            Write-Error "Release branch $ReleaseName not found."
            return;
        }
    }

    $releaseRefName = $releaseBranch.ShortRefName;
    $ReleaseName = $releaseBranch.Name;
    ExecuteGitCommand 'git checkout' "-b release/$ReleaseName/$Name --no-track $releaseRefName" '--progress'
}

function Push-GitFeature {
    <#
    .SYNOPSIS
    Pushes feature branch to origin.
    
    .DESCRIPTION
    Pushes specified feature branch to origin. If no branch name specified the current feature branch will be pushed.
    
    .PARAMETER Name
    Branch name without feature prefix.

    .EXAMPLE
    Push-GitFeature cool-stuff

    .LINK
    Push-GitReleaseFix
    #>
    [CmdletBinding(SupportsShouldProcess=$false)]
    param(
        [Parameter(Mandatory=$false, 
                   Position=0, 
                   ParameterSetName="Name",
                   HelpMessage="Branch name")]
        [ValidateNotNullOrEmpty()]
        [ArgumentCompleter({ & $PoshGitWorkflow.LocalFeatureNameArgumentCompleter })]
        [string]
        $Name
    )

    trap {
        return;
    }

    $branch = GetFeatureBranches | Where {$_.IsLocal -and (HasNameOrCurrent $_ $Name)};
    PushBranch $branch;
}

function Push-GitReleaseFix {
    <#
    .SYNOPSIS
    Pushes release fix branch to origin.
    
    .DESCRIPTION
    Pushes specified release fix branch to origin. If no branch name specified the current release fix branch will be pushed.
    
    .PARAMETER Name
    Branch name without release branch prefix.

    .EXAMPLE
    Push-GitReleaseFix bug-fix

    .LINK
    Push-GitFeature
    #>
    [CmdletBinding(SupportsShouldProcess=$false)]
    param(
        [Parameter(Mandatory=$false, 
                   Position=0, 
                   ParameterSetName="Name",
                   HelpMessage="Branch name")]
        [ValidateNotNullOrEmpty()]
        [ArgumentCompleter({ & $PoshGitWorkflow.LocalReleaseFixNameArgumentCompleter })]
        [string]
        $Name
    )

    trap {
        return;
    }

    $branch = GetReleaseFixBranches | Where {$_.IsLocal -and (HasNameOrCurrent $_ $Name)};
    PushBranch $branch;
}

function Complete-GitFeature {
    <#
    .SYNOPSIS
    Pushes feature branch and submits pull request.
    
    .DESCRIPTION
    Pushes feature branch to origin and submits pull request (if configured). If no branch name specified the current feature branch will be used.
    
    .PARAMETER Name
    Branch name without feature prefix.

    .EXAMPLE
    Complete-GitFeature cool-stuff

    .LINK
    Set-GitPullRequestUrl

    .LINK
    Complete-GitReleaseFix
    #>
    [CmdletBinding(SupportsShouldProcess=$false)]
    param(
        [Parameter(Mandatory=$false, 
                   Position=0, 
                   ParameterSetName="Name",
                   HelpMessage="Branch name")]
        [ValidateNotNullOrEmpty()]
        [ArgumentCompleter({ & $PoshGitWorkflow.FeatureNameArgumentCompleter })]
        [string]
        $Name
    )

    trap {
        "Error: $_";
        return;
    }

    $branch = GetFeatureBranches | Where {HasNameOrCurrent $_ $Name};
    PushBranch $branch;
    SubmitPullRequest $branch;    
}

function Complete-GitReleaseFix {
    <#
    .SYNOPSIS
    Pushes release fix branch and submits pull request.
    
    .DESCRIPTION
    Pushes release fix branch to origin and submits pull request (if configured). If no branch name specified the current release fix branch will be used.
    
    .PARAMETER Name
    Branch name without release branch prefix.

    .EXAMPLE
    Complete-GitReleaseFix bug-fix

    .LINK
    Set-GitPullRequestUrl

    .LINK
    Complete-GitFeature
    #>
    [CmdletBinding(SupportsShouldProcess=$false)]
    param(
        [Parameter(Mandatory=$false, 
                   Position=0, 
                   ParameterSetName="Name",
                   HelpMessage="Branch name")]
        [ValidateNotNullOrEmpty()]
        [ArgumentCompleter({ & $PoshGitWorkflow.ReleaseFixNameArgumentCompleter })]
        [string]
        $Name
    )

    trap {
        "Error: $_";
        return;
    }

    $branch = GetReleaseFixBranches | Where {HasNameOrCurrent $_ $Name};
    PushBranch $branch;
    SubmitPullRequest $branch;    
}

function Complete-GitRelease {
    <#
    .SYNOPSIS
    Merges release branch to master.
    
    .DESCRIPTION
    Merges release branch to master, creates tag with merged branch name and pushes changes to upstream.
    
    .PARAMETER Name
    Branch name without release prefix.

    .PARAMETER Message
    Release tag message.

    .EXAMPLE
    Complete-GitRelease v1.1 -Message 'Awesome release'

    .LINK
    Complete-GitReleaseFix
    #>
    [CmdletBinding(SupportsShouldProcess=$false)]
    param(
        [Parameter(Mandatory=$false, 
                   Position=0, 
                   HelpMessage="Branch name")]
        [ValidateNotNullOrEmpty()]
        [ArgumentCompleter({ & $PoshGitWorkflow.ReleaseNameArgumentCompleter })]
        [string]
        $Name,
        [Parameter(Mandatory=$false, 
                   Position=1, 
                   HelpMessage="Tag message")]
        [ValidateNotNullOrEmpty()]
        [string]
        $Message
    )

    trap {
        return;
    }

    SyncFork

    $branches = @(GetReleaseBranches);
    $branch = $branches | Where {HasNameOrCurrent $_ $Name};

    if ([System.String]::IsNullOrWhitespace($Name) -and $branch -eq $null -and $branches.Length -eq 1) {
        $branch = $branches[0];
    }

    if ($branch -eq $null) {
        if ([System.String]::IsNullOrWhitespace($Name)) {
            Write-Error "No release branches found";
        }
        else {
            Write-Error "Branch 'release/$Name' not found";
        }
        return;
    }

    $Name = $branch.Name;

    $commitId = ExecuteGitCommand 'git rev-parse' $branch.ShortRefName;

    if ($branch.IsLocal) {
        ExecuteGitCommand 'git branch' "-D release/$Name";
    }

    $messageParameter = '';
    if (-not [System.String]::IsNullOrWhitespace($Message)) {
        $messageParameter = "--message='$Message'";
    }

    ExecuteGitCommand 'git merge' "--no-ff -m `"Merge 'release/$Name'`" $commitId";

    if (HasMergeConflicts) {
        return;
    }

    ExecuteGitCommand 'git tag' "$messageParameter release/$Name $commitId"
    ExecuteGitCommand 'git push' "upstream --delete release/$Name";
    ExecuteGitCommand 'git push' '--set-upstream upstream';
    ExecuteGitCommand 'git branch' '--set-upstream-to origin'
    ExecuteGitCommand 'git push' "upstream --tags"
}

function Set-GitPullRequestUrl {
    <#
    .SYNOPSIS
    Sets submit pull request page URL in local git config.
    
    .DESCRIPTION
    Creates or updates local git config section 'workflow' and sets 'pullrequesturl' key value to the specified URL.
    
    .PARAMETER Url
    Submit pull request page URL.
    
    The URL can be in a form of a template with this placeholders:
    {0} - sourceRef
    {1} - targetRef
    
    GitHub URL example:
    https://github.com/<repo-owner-id>/<original-repo-id>/compare/{1}...<my-github-user-id>:{0}

    Visual Studio Online URL example:
    https://<my-account-id>.visualstudio.com/_git/<my-repo-id>/pullrequestcreate?sourceRef={0}&targetRef={1}&sourceRepositoryId=<my-fork-GUID>&targetRepositoryId=<main-repo-GUID>
    
    .EXAMPLE
    Set-GitPullRequestUrl 'https://github.com/octocat/Spoon-Knife/compare/master...my-github-user-id:master'

    .EXAMPLE
    Set-GitPullRequestUrl 'https://my-account.visualstudio.com/_git/my-repo/pullrequestcreate?sourceRef={0}&targetRef={1}&sourceRepositoryId=my-fork-repo-GUID&targetRepositoryId=main-repo-GUID'
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false, 
                   Position=0, 
                   ParameterSetName="Url",
                   HelpMessage="Pull request URL")]
        [System.Uri] $Url
    )
    
    trap {
        return;
    }

    SetGitConfigValue $PoshGitWorkflow.PullRequestUrlConfigKey $Url;
}

function SubmitPullRequest {
    [CmdletBinding()]
    param ($branch)
    
    $pullRequestUrl = GetGitConfigValue $PoshGitWorkflow.PullRequestUrlConfigKey;

    if ([System.String]::IsNullOrWhitespace($pullRequestUrl)) {
        return;
    }

    [System.Reflection.Assembly]::LoadWithPartialName('System.Web') | out-null;
    $sourceRef = $branch.ShortLocalRefName;
    $targetRef = 'master';

    if ($branch.IsSubBranch -and -not $branch.IsOther) {
        $targetRef = $branch.ShortLocalParentRefName;
    }

    $sourceRef = [System.Web.HttpUtility]::UrlEncode($sourceRef);
    $targetRef = [System.Web.HttpUtility]::UrlEncode($targetRef);

    # "https://rebtel.visualstudio.com/_git/Backend/pullrequestcreate?sourceRef={0}&targetRef={1}&sourceRepositoryId=9b139ae4-3a6c-4946-9837-a14c15243bf3&targetRepositoryId=28e641a9-a204-46c4-b22a-303204901fe9"
    $pullRequestUrl = [System.String]::Format($pullRequestUrl, $sourceRef, $targetRef);

    (New-Object -Com Shell.Application).Open($pullRequestUrl);
}

function SyncFork {
    [CmdletBinding(SupportsShouldProcess=$false)]
    Param()

    $progress = 0;
    $progressStep = 100 / 8;

    if (HasMergeConflicts) {
        throw 'Merge conflicts detected.';
    }
    
    $popStash = $false;

    if (IsDirty) {
        Write-Progress -Activity 'Syncing' -Status "Stashing changes..." -PercentComplete $progress
        ExecuteGitCommand 'git stash save --include-untracked';
        $popStash = $true;        
    }

    $progress += $progressStep;
    Write-Progress -Activity 'Syncing' -Status "Fetching latest changes from upstream..." -PercentComplete $progress
    ExecuteGitCommand 'git fetch --prune' 'upstream' '--progress --verbose'

    $progress += $progressStep;
    Write-Progress -Activity 'Syncing' -Status "Checkout master" -PercentComplete $progress
    ExecuteGitCommand 'git checkout' 'master' '--progress'

    $progress += $progressStep;
    Write-Progress -Activity 'Syncing' -Status "Rebasing master onto upstream/master" -PercentComplete $progress
    ExecuteGitCommand 'git merge --ff-only' 'upstream/master' '--verbose'

    $progress += $progressStep;
    Write-Progress -Activity 'Syncing' -Status "Pushing master" -PercentComplete $progress
    ExecuteGitCommand 'git push' 'origin master' '--progress --verbose'

    $progress += $progressStep;
    Write-Progress -Activity 'Syncing' -Status "Cleaning up stale origin branches" -PercentComplete $progress
    PruneRemoteBranches 'origin'

    $progress += $progressStep;
    Write-Progress -Activity 'Syncing' -Status "Cleaning up stale upstream branches" -PercentComplete $progress
    PruneRemoteBranches 'upstream'

    if ($popStash) {
        $progress += $progressStep;
        Write-Progress -Activity 'Syncing' -Status "Restoring stashed changes..." -PercentComplete $progress
        ExecuteGitCommand 'git stash pop';
    }

    if (HasMergeConflicts) {
        throw 'Merge conflicts detected.';
    }

    Write-Progress -Activity 'Syncing' -Completed
}

function PruneRemoteBranches {
    [CmdletBinding()]
    param ([string]$remote)
    
    $result = ExecuteGitCommand 'git remote prune' $remote;
    $staleBranches = [System.Collections.ArrayList]::new();

    $prunedBranchPrefix = '* [pruned] ';

    foreach ($line in $result) {
        $line = $line.Trim();

        if ($line.StartsWith($prunedBranchPrefix)) {
            # prune output looks like this: * [would prune] origin/feature/branch-name
            $branchName = $line.Substring($prunedBranchPrefix.Length + $remote.Length + 1);
            $staleBranches.Add($branchName);
        }
    }

    if ($staleBranches.Count -eq 0) {
        return;
    }

    $localBranchesToDelete = '';
    GetAllBranches | Where {$_.IsLocal -and $staleBranches.Contains($_.ShortRefName)} | ForEach-Object {$localBranchesToDelete += $_.ShortRefName + ' '};

    if ($localBranchesToDelete.Length -eq 0) {
        return;
    }

    ExecuteGitCommand 'git branch -D' $localBranchesToDelete '--verbose'
}

function PushBranch {
    [CmdletBinding(SupportsShouldProcess=$false)]
    param($branch)

    if ($branch -eq $null) {
        Write-Error "Branch $Name could not be found";
        throw 'Branch does not exist.';
    }

    ExecuteGitCommand 'git push --set-upstream origin' $branch.ShortRefName '--verbose --progress'
}

function IsDirty {
    $changes = git status --porcelain;

    return $changes -ne $null -and $changes.Length -ne 0;
}

function HasMergeConflicts {
    $changes = git status --porcelain;

    if ($changes -eq $null -or $changes.Length -eq 0) {
        return $false;
    }

    $conflictStatuses = 'DD', 'AU', 'UD', 'UA', 'DU', 'AA', 'UU';

    return ($changes | Where {$conflictStatuses.Contains($_.Substring(0, 2))}).Length -gt 0;
}

function HasNameOrCurrent {
    param($branch, $name)

    if ([System.String]::IsNullOrEmpty($name) -and $branch.IsHead) {
        return $branch
    }

    if ($branch.Name -eq $name) {
        return $branch;
    }

    return $null;
}

function GetReleaseBranches () {
    GetAllBranches | Where {$_.IsRelease -and -not $_.IsSubBranch}
}

function GetReleaseFixBranches () {
    GetAllBranches | Where {$_.IsRelease -and $_.IsSubBranch}
}

function GetHotfixBranches () {
    GetAllBranches | Where {$_.IsHotfix -and -not $_.IsSubBranch}
}

function GetHotfixFixBranches () {
    GetAllBranches | Where {$_.IsHotfix -and $_.IsSubBranch}
}

function GetFeatureBranches () {
    GetAllBranches | Where {$_.IsFeature}
}

function GetAllBranches () {
    $trackedRefs = @{};
    $branches = @{};

    git branch --list --all --format='%(refname)>>%(refname:short)>>%(upstream)>>%(HEAD)' | 
        ForEach-Object {
            $values = $_ -split '>>';
        
            $refName = $values[0];
            $shortRefName = $values[1];
            $upstream = $values[2];
            $isHead = $values[3] -eq '*';

            # don't parse manually, use git:
            # git branch --all --format '%(upstream)    %(upstream:short)    %(upstream:track)    %(upstream:trackshort)    %(upstream:remotename)    %(upstream:lstrip=3)'
            # gives:
            # refs/remotes/origin/feature/vsts-itp    origin/feature/vsts-itp    [ahead 8]    >    origin    feature/vsts-itp
            $refParts = $refName -split '/';
        
            $isTracking = [System.String]::IsNullOrEmpty($upstream) -ne $true;
            if ($isTracking)
            {
                $trackedRefs[$upstream] = '';
            }

            $isLocal = $refParts[1] -eq 'heads';

            # local - 2: refs/heads/feature/branch_name
            # remote - 3: refs/remotes/origin/feature/branch_name
            $typePartIndex = 3;
            if ($isLocal)
            {
                $typePartIndex = 2;
            }

            $isFeature = $false;
            $isRelease = $false;
            $isHotfix = $false;

            $type = $refParts[$typePartIndex];
            $isFeature = $type -eq 'feature';
            $isRelease = $type -eq 'release';
            $isHotfix = $type -eq 'hotfix';

            $isOther = ($isFeature -or $isRelease -or $isHotfix) -ne $true;

            $name = $shortRefName;

            if ($isOther -eq $false)
            {
                $nameparts = @($refParts | Select -skip ($typePartIndex + 1));
                $name = [System.String]::Join('/', $nameparts);
            }
            
            $localRefParts = @($refParts | Select -Skip ($typePartIndex));

            $isSubBranch = $false;
            if ($localRefParts.Length -gt 2) {
                $isSubBranch = $true;
            }

            $shortLocalRefName = [System.String]::Join('/', $localRefParts);

            if ($localRefParts.Length -gt 1) {
                $shortLocalParentRefName = [System.String]::Join('/', @($localRefParts | Select -SkipLast 1));
            }
        
            $branch = [PSCustomObject]@{
                RefName = $refName;
                ShortRefName = $shortRefName;
                ShortLocalRefName = $shortLocalRefName;
                ShortLocalParentRefName = $shortLocalParentRefName;
                Upstream = $upstream;
                Name = $name;
                IsHead = $isHead;
                IsLocal = $isLocal;
                IsFeature = $isFeature;
                IsRelease = $isRelease;
                Ishotfix = $isHotfix;
                IsOther = $isOther;
                IsSubBranch = $isSubBranch;
                Type = $type;
            };
        
            $branches[$branch.RefName] = $branch;
        };

    foreach($ref in $trackedRefs.Keys)
    {
        $branches.Remove($ref);
    }

    $branches.Values | sort RefName;
}

function NameStartsWith {
    param($branch, $value)

    return $branch.Name.StartsWith($value, $true, [System.Globalization.CultureInfo]::InvariantCulture);
}

function GetStorageFolder () {
    $moduleName = [System.IO.Path]::GetFileNameWithoutExtension($PSCommandPath);
    $applicationDataFolder = [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::ApplicationData);
    return $applicationDataFolder | Join-Path -ChildPath $moduleName;
}

function ToBranchCompletionResult($branch) {
    return [System.Management.Automation.CompletionResult]::new($branch.Name, $branch.Name, 'ParameterValue', $branch.RefName);
}

function GetGitConfigValue {
    [CmdletBinding()]
    param (
        [string] $key
    )
    
    ExecuteGitCommand 'git config --get' $key;
}

function SetGitConfigValue {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, Position=0)]
        [string] $key,
        [Parameter(Mandatory=$false, Position=1)]
        [string] $value
    )
    
    if ([System.String]::IsNullOrEmpty($value)) {
        ExecuteGitCommand 'git config --unset' $key;    
    }
    else {
        ExecuteGitCommand 'git config' "$key '$value'";
    }
}

function ExecuteGitCommand {
    [CmdletBinding(SupportsShouldProcess=$false)]
    param(
        [Parameter(Mandatory=$true, Position=0)]
        [ValidateNotNullOrEmpty()]
        [string]$Command,

        [Parameter(Mandatory=$false, Position=1)]
        [ValidateNotNullOrEmpty()]
        [string]$Parameters = '',

        [Parameter(Mandatory=$false, Position=2)]
        [ValidateNotNullOrEmpty()]
        [string]$VerboseParameters = '')

    if ($VerbosePreference -ne 'SilentlyContinue') {
        $Command = $Command + " " + $VerboseParameters;
    }

    $Command = $Command + " " + $Parameters;

    if ($VerbosePreference -ne 'SilentlyContinue') {
        Write-Verbose $Command
    }

    iex $Command

    if ($LASTEXITCODE -ne 0) {
        throw 'Failed'
    }
}
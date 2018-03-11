[![PowerShell Gallery](https://img.shields.io/powershellgallery/v/posh-git-workflow.svg?style=flat-square)](https://www.powershellgallery.com/packages/posh-git-workflow/)
# posh-git-workflow
posh-git-workflow is a PowerShell module that automates [GitHub Flow](https://guides.github.com/introduction/flow/) and similar branching models with a set of cmdlets to sync a fork, create/push a feature branch and submit a pull request. 

It also facilitates teams with longer release cycles with a set of release branch management cmdlets.

## Notes
posh-git-workflow is currently in it's infancy with only the basic functionality implemented. There's still a lot of things left to do to make it user friendly and more useful.

# Installation
```PowerShell
PS> Install-Module -Name posh-git-workflow
```

# Using posh-git-workflow
## Prerequisites
Configure a remote that points to the upstream repository in Git ([more info](https://help.github.com/articles/configuring-a-remote-for-a-fork/)):
```PowerShell
PS> git remote add upstream <original-repo-url>
```

Configure pull request URL by calling Set-PullRequestUrl cmdlet with a valid URL. 

The **{0}** and **{1}** are string format items and will be replaced with source and target branch names respectively.

**GitHub**

```PowerShell
PS> Set-PullRequestUrl 'https://github.com/<repo-owner-id>/<original-repo-id>/compare/{1}...<my-github-user-id>:{0}'
```

Replace `<repo-owner-id>`, `<original-repo-id>` and `<my-github-user-id>` with valid values.

**Visual Studio Online**

```PowerShell
PS> Set-PullRequestUrl 'https://<my-account-id>.visualstudio.com/_git/<my-repo-id>/pullrequestcreate?sourceRef={0}&targetRef={1}&sourceRepositoryId=<my-fork-GUID>&targetRepositoryId=<main-repo-GUID>'
```

Replace `<my-account-id>`, `<my-repo-id>`, `<my-fork-GUID>` and `<main-repo-GUID>` with respective values.

The **easiest way** to get the right URL is to navigate to your repo, click 'New Pull Request' and **copy the URL**.

## Working on a feature
Create a new feature branch
```PowerShell
PS> New-Feature cool-stuff
```

New-Feature will sync your fork and create a new 'feature/cool-stuff' branch.

When ready to submit a pull request

```PowerShell
PS> Complete-Feature
```

Complete-Feature will then push 'feature/cool-stuff' branch to origin and open a web page where you can submit your pull request.

To push your feature branch without submitting a pull request
```PowerShell
PS> Push-Feature
```

# Other recommended modules
[posh-git](https://github.com/dahlbyk/posh-git)  is a PowerShell module that integrates Git and PowerShell by providing Git status summary information that can be displayed in the PowerShell prompt. 

posh-git also provides tab completion support for common git commands, branch names, paths and more.


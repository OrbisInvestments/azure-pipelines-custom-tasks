# Orbis Azure Pipeline Tasks

Custom Azure Pipeline Tasks

---
## Dedupe Git Repositories Task

An Azure Pipelines task that deduplicates clones of Git repositories on self-hosted Windows agent servers.

### Build Status

[![Build Status](https://dev.azure.com/orbisinvestments/Open%20Source/_apis/build/status/Azure%20Pipeline%20Custom%20Tasks/Centralize%20Git%20Repositories%20Task?branchName=master)](https://dev.azure.com/orbisinvestments/Open%20Source/_build/latest?definitionId=1&branchName=master)

### Motivation

Currently the Azure Pipelines Agent will inefficiently clone the same Git repository multiple times for different pipelines. The number of clones the agent will create is a function of the number of pipelines that build the same Git repository. For large repositories with many pipelines this can result in significant disk usage on the agent servers. More details can be found in this issue here: [microsoft/azure-pipelines-agent/1506](https://github.com/microsoft/azure-pipelines-agent/issues/1506)

The **Dedupe Git Repositories Task** is a task that circumvents this issue by running a *post job execution* script to deduplicate clones of the same Git repository at the end of the pipeline. 

### Installation

Head over to the latest Dedupe Git Repositories [release](https://github.com/OrbisInvestments/azure-pipelines-custom-tasks/releases), then download and extract **DedupeGitRepos.zip**

Use [tfx](https://github.com/Microsoft/tfs-cli) to upload the extracted task to your account under a suitably permissioned identity or PAT:

`tfx login`

`tfx build tasks upload --task-path .`


### How to use

###  How it works

When executed in a pipeline, the Dedupe Git Repositories Task will determine if the repository clone that was used was a *shared* clone. If not, then the following actions are performed:

1. Either:
    1. Move the repository into a shared location (Agent.WorkFolder\g) if a clone for the same repository does not already exist. This becomes the *shared* clone
    2. delete the clone if a shared clone does already exist
2. Update the pipeline's cached working directory configuration to point at the shared clone

The next time the pipeline is executed by the agent will use the shared clone for its sources. 

To avoid concurrency issues shared clones are created [per-agent](https://github.com/microsoft/azure-pipelines-agent/issues/1506#issuecomment-381361454).

### TODO

- [ ] Automation script to add task to pipelines


## Credits

[Git Logo](./DedupeGitReposV0/icon.png) by [Jason Long](https://twitter.com/jasonlong) is licensed under the [Creative Commons Attribution 3.0 Unported License](https://creativecommons.org/licenses/by/3.0/).

---





# Orbis Azure Pipeline Tasks

Custom Azure Pipeline Tasks

---
## Dedupe Git Repositories Task

An Azure Pipelines task that deduplicates clones of Git repositories on self-hosted Windows agent servers.

### Motivation

For different Azure Pipelines that build from the same Git repository, the Azure Pipelines Agent will create a separate clone for each pipeline. For large repositories with many pipelines this can result in significant disk usage on the agent servers. More details are in this issue here: [microsoft/azure-pipelines-agent/1506](https://github.com/microsoft/azure-pipelines-agent/issues/1506)


### Build Status

[![Build Status](https://dev.azure.com/orbisinvestments/Open%20Source/_apis/build/status/Azure%20Pipeline%20Custom%20Tasks/Centralize%20Git%20Repositories%20Task?branchName=master)](https://dev.azure.com/orbisinvestments/Open%20Source/_build/latest?definitionId=1&branchName=master)


### TODO

- [ ] Automation script to add task to pipelines


## Credits

[Git Logo](./DedupeGitReposV0/icon.png) by [Jason Long](https://twitter.com/jasonlong) is licensed under the [Creative Commons Attribution 3.0 Unported License](https://creativecommons.org/licenses/by/3.0/).

---





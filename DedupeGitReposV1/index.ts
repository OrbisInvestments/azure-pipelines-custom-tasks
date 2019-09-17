import tl = require("azure-pipelines-task-lib/task");
import fs = require("fs");

var workFolder: string = tl.getVariable("Agent.WorkFolder");

var repository: string = tl.getVariable("Build.Repository.Id");
var repositoryType: string = tl.getVariable("Build.Repository.Provider");
var sourceFolder: string = tl.getVariable("Build.Repository.LocalPath");

var sharedGitFolderName: string = "g";
var sharedGitFolderPath: string = tl.resolve(workFolder, sharedGitFolderName);
var configFileName: string = "DedupeGitReposConfig.json";
var configFilePath: string = tl.resolve(sharedGitFolderPath, configFileName);
var gitProviders = ["TfsGit", "Git", "GitHub"];

var useSymlink: boolean = false;

function writeConfig(config: any) {
    console.log("Writing configuration to " + configFilePath);

    if (!tl.exist(sharedGitFolderPath)) {
        tl.mkdirP(sharedGitFolderPath);
    }

    tl.writeFile(configFilePath, JSON.stringify(config));
}

async function run() {
    try {
        tl.debug("workFolder: " + workFolder);
        tl.debug("repository: " + repository);
        tl.debug("sourceFolder: " + sourceFolder);
        tl.debug("sharedGitFolderPath: " + sharedGitFolderPath);
        tl.debug("configFilePath: " + configFilePath);

        if (sourceFolder.indexOf(sharedGitFolderPath) == 0) {
            console.log(sourceFolder + " is already using deduplicated repo at " + sourceFolder);
            return;
        }

        if (gitProviders.indexOf(repositoryType) == -1) {
            tl.setResult(tl.TaskResult.Failed, "Unsupported repository type " + repositoryType + "; must be one of " + gitProviders.join(","));
            return;
        }

        var config;

        if (!tl.exist(configFilePath)) {
            console.log("Creating configuration for this agent");
            config = {
                description: "Configuration for Dedupe Git Repositories custom build step",
                lastFolderId: 1,
                repos: [
                    {
                        repository: repository,
                        path: sharedGitFolderName + "/1"
                    }
                ]
            };

            writeConfig(config);
        }
        else {
            config = JSON.parse(fs.readFileSync(configFilePath, { encoding: "utf8" }));
        }

        var repo = config.repos.find((r: any) => r.repository == repository);

        if (!repo) {
            console.log("Configuring repository for deduplication");

            config.lastFolderId++;

            repo = {
                repository: repository,
                path: sharedGitFolderName + "/" + config.lastFolderId.toString()
            };

            config.repos.push(repo);

            writeConfig(config);
        }

        var sharedRepoFullPath: string = tl.resolve(workFolder, repo.path);
        var migrate: boolean = false;

        if (useSymlink) {
            var sourceFolderIsLink = fs.lstatSync(sourceFolder).isSymbolicLink();
            var sourceFolderTarget: string = sourceFolderIsLink ? fs.readlinkSync(sourceFolder, { encoding: "utf8" }) : "";

            tl.debug("sourceFolderIsLink: " + sourceFolderIsLink);
            tl.debug("sourceFolderTarget: " + sourceFolderTarget);

            if (sourceFolderIsLink && sourceFolderTarget == sharedRepoFullPath) {
                console.log("Build already symlinked to deduped repository at " + sharedRepoFullPath);
            }
            else {
                migrate = true;
            }
        }
        else {
            var sourceFolderMappingPath: string = tl.resolve(workFolder, "SourceRootMapping", tl.getVariable("System.CollectionId"), tl.getVariable("Build.BuildId"), "SourceFolder.json");

            var sourceFolderMapping = JSON.parse(fs.readFileSync(sourceFolderMappingPath, { encoding: "utf8" }));

            // Test for repo.path, since sourceFolderMapping.build_sourcesdirectory is relative to _work.
            if (sourceFolderMapping.build_sourcesdirectory == repo.path) {
                console.log("SourceFolderMapping already in place");
            }
            else {
                console.log("Changing SourceFolderMapping to point to " + repo.path);

                sourceFolderMapping.build_sourcesdirectory = repo.path;

                tl.writeFile(sourceFolderMappingPath, JSON.stringify(sourceFolderMapping));

                migrate = true;
            }
        }

        if (migrate) {
            console.log("Migrating build to using a deduped repository at " + sharedRepoFullPath);

            if (!tl.exist(sharedRepoFullPath)) {
                if (!tl.exist(sharedGitFolderPath)) {
                    console.log("Creating shared directory " + sharedGitFolderPath + " for repositories");
                    tl.mkdirP(sharedGitFolderPath);
                }

                console.log("Moving repository to shared directory from " + sourceFolder);
                tl.mv(sourceFolder, sharedRepoFullPath);
            }
            else {
                console.log("Repository has already been deduped, removing source folder contents for build at " + sourceFolder);
                tl.rmRF(sourceFolder);
            }

            if (useSymlink) {
                console.log("Symlinking source folder at " + sourceFolder + " to deduped repository location at " + sharedRepoFullPath);
                fs.symlinkSync(sharedRepoFullPath, sourceFolder, "dir");
            }
        }

        console.log("Done");
    }
    catch (err) {
        tl.setResult(tl.TaskResult.Failed, err.message);
    }
}

run();
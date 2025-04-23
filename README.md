# This is a readme for my jsonresume repo

You need to configure git to locate any hooks in the .githooks folder instead of the .git folder. 
This is done with the git config core.hooksPath ./.githooks command, and make sure you save any hooks files with the unix line endings (LF) instead of the windows line endings (CRLF).

Prerequisites
- Install jq


## How to deploy

All your resumes must reside inside the resumes folder.
In the metasection of the resume you must include resumetype and language

Then in the deployment-configuration you configure what resume you would like to have deployed.

The pre-push hook will then look thru your resumes folder and check if the resumetype and language matches the deployment-configuration, and then copy the content of the file to the resume.json file, and then deploy it to a gist.

In order to deploy your resume to your own gist you must update the gist_id to use your own, in the .github/workflows/gist.yml.

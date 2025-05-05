# This is a readme for my jsonresume repo


## How to deploy

Deployment are done using github actions
All your resumes must reside inside the resumes folder.
In the metasection of the resume you must include resumetype and language

### config.json
Then in the deployment configuration file named config.json you configure what resume you would like to have deployed. There is also an option to configure dryrun. This will bypass any git commands. Use 0 to disable dryrun and 1 to enable it. This is useful for testing the shell script without actually pushing anything to the remote repository.
You must also add your own gist_id to to deploy to your gist.

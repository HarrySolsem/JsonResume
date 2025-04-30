# This is a readme for my jsonresume repo


## How to deploy

Deployment are done using github actions
All your resumes must reside inside the resumes folder.
In the metasection of the resume you must include resumetype and language

### deployment-configuration.json
Then in the deployment configuration file named config.json you configure what resume you would like to have deployed. There is also an option to configure dryrun. This will bypass any git commands. Use 0 to disable dryrun and 1 to enable it. This is useful for testing the shell script without actually pushing anything to the remote repository.

### Resume manipulation
The shell script resume_manipulation will look thru your resumes folder and check if the resumetype and language matches the deployment-configuration, and then copy the content of the file to the resume.json file, and then deploy it to a gist.

In order to deploy your resume to your own gist you must update the gist_id to use your own, in the repository variables.

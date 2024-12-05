# Custom Bashrc file


## Prereqs:
- AWS CLI v2
- - CLI Profiles
- Git
- fzf
- Some commands require Terraform


## Description
Custom Bash profile with the following prompt:
{awsprofile}{pythonvenv}@{parentfolder}/{currentfolder}[{gitbranch}]->$



## Functions and aliases

### aws
#### awsprofile

Interactive prompt to select between available AWS CLIv2 profiles.
I recommend using SSO profiles.

#### awsi

Runs "aws sts get-caller-identity"

### Git
#### gc
Runs the git_append custom function. Looks for Jira Ticket number at start of branch name and prepends it to your commit message. Example "gc -a "my message" gives commit message: "scp-1234/my message"

#### gbranch
Gets branches for the repository and lets you interactively select one to check out.

### Terraform
#### tf

Alias for "terraform"

#### tfi

Runs "terraform init"

#### tfp

Runs "terraform plan"

#### tffmt

Runs "terraform fmt"

#### tfdoc

Injects Terraform Docs in README.md. Requires Terraform Docs to be installed.

#### tfa

Checks what your current AWS caller identity is and runs "terraform apply --auto-approve" if your caller identity is your allowed account ID. NB! Before use remember to update the AWS Account ID in the "tfa" function, line 37.


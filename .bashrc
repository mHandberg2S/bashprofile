# Function to get the virtual environment name
get_venv_prompt() {
    if [[ -n "$VIRTUAL_ENV" ]]; then
        echo "($(basename "$VIRTUAL_ENV")) "
    fi
}

# Update the prompt
update_prompt() {
    PS1="\[\e[31m\]$(get_aws_profile_prompt)\[\e[m\]\
$(get_venv_prompt)\
\[\e[34m\]@\[\e[m\]\[\e[32m\]$(basename "$(dirname "$PWD")")/\W\[\e[m\]\
\[\e[34m\]:\[\e[m\]\[\e[33m\]$(parse_git_branch)\[\e[m\]->\
\[\e[m\]\$\[\e[37m\]\[\e[m\]"
}

# Apply the prompt update function
PROMPT_COMMAND=update_prompt


alias tf="terraform"
alias tfi="terraform init"
alias tfp="terraform plan"
alias tffmt="terraform fmt"
alias cbashrc="code ~/.bashrc"
alias sbashrc="source ~/.bashrc"
alias gc='git_append'
alias awsi="aws sts get-caller-identity"
tfa() {
    # Get the AWS account ID using aws sts get-caller-identity
    account_id=$(aws sts get-caller-identity --query 'Account' --output text)

    # Check if AWS CLI v2 profile is set to a specific account ID
    if [[ $account_id == "1" ]]; then

            # Run terraform apply with auto-approval
            terraform apply --auto-approve
    else
        echo "AWS CLI is not set to the specific account ID." 
    fi
}

export AWS_PROFILE=$(aws configure get default.profile 2>/dev/null)

function awsprofile() {
  # Get the list of profiles excluding "default"
  profiles=$(aws configure list-profiles | grep -v '^default$')

  # Use fzf for interactive selection
  selected_profile=$(echo "$profiles" | fzf --prompt="Select AWS profile: ")

  if [ -n "$selected_profile" ]; then
    # Set the selected profile as the default
    aws configure set default.profile "$selected_profile"
    echo "Default AWS profile set to: $selected_profile"
    
    # Export the selected profile
    export AWS_PROFILE="$selected_profile"
    
    # Update PS1 with the new AWS profile
    export PS1="\[\e[31m\]$(get_aws_profile_update)\[\e[m\]\[\e[34m\]@\[\e[m\]\[\e[32m\]\$(basename \"\$(dirname \"\$PWD\")\")/\W\[\e[m\]\[\e[34m\]:\[\e[m\]\[\e[33m\]$(parse_git_branch)\[\e[m\]->\[\e[m\]\\$\[\e[37m\]\[\e[m\]"
  else
    echo "No profile selected."
  fi
}

function git_append {
  # Create commit prefix based on branch name
  commit_prefix=$(git symbolic-ref --short HEAD | awk -F '-' '{print $1"-"$2}')

  #check if commit message starts with [feat|chore|fix|hotfix]
  message_prefix=$(echo $2 | awk -F ':' '{print $1}')

  echo $message_prefix
  echo "<# git commit $1 -m '$commit_prefix/$2'"
  echo "<#"
  git commit $1 -m "$commit_prefix/$2"
}
get_aws_profile_update() {
    local aws_profile
    aws_profile=$(aws configure get default.profile 2>/dev/null)
    [ -n "$aws_profile" ] && echo "$aws_profile"
}
get_aws_profile_prompt() {
    awk -F' *= *' '/^\[/{profile=$2} /^\[/{in_profile=0} /^\[default\]/{in_profile=1} in_profile && /^profile *= */{print $2}' ~/.aws/config

}
function parse_git_branch() {
	BRANCH=`git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/\1/'`
    echo "[${BRANCH}]"
}

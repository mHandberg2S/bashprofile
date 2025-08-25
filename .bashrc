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

alias code='open -a "Visual Studio Code"' # open file or folder in VSCode e.g. code ~/.zshrc

alias tf="terraform"
alias tfi="terraform init"
alias tfp="terraform plan"
alias tffmt="terraform fmt"
alias tfdoc='terraform-docs markdown table --output-file README.md --output-mode inject .'
alias cbashrc="code ~/.bashrc"
alias sbashrc="source ~/.bashrc"
alias gc='git_append'
alias awsi="aws sts get-caller-identity"
tfa() {
    # Get the AWS account ID using aws sts get-caller-identity
    account_id=$(aws sts get-caller-identity --query 'Account' --output text)

    # Check if AWS CLI v2 profile is set to a specific account ID
    if [[ $account_id == "INSERT-AWS-ACCOUNT-ID-HERE" ]]; then

            # Run terraform apply with auto-approval
            terraform apply --auto-approve
    else
        echo "AWS CLI is not set to the specific account ID." 
    fi
}

export AWS_PROFILE=$(aws configure get default.profile 2>/dev/null)

gpr() {
    # Create commit prefix based on branch name
  commit_prefix=$(git symbolic-ref --short HEAD | awk -F '-' '{print $1"-"$2}')

  gh pr create \
    --assignee "@me" \
    --base $1 \
    --title "$commit_prefix/$2" \
    --draft
}

function awsp() {
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

function gswitch() {
  # Check if the current directory is a Git repository
  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "Not a Git repository!"
    return 1
  fi

  # Use git branch to get a list of branches, send it to fzf for selection
  local branch
  branch=$(git remote prune origin && git branch -a --color=always | \
    fzf --ansi --preview="git log --color=always -n 5 --pretty=format:'%s' {1}" | \
    sed -E 's/^.* -> //; s/^..//; s#remotes/[^/]+/##')

  # If no branch was selected, exit the function
  if [[ -z "$branch" ]]; then
    echo "No branch selected."
    return 1
  fi

  # Check out the selected branch
  git switch "$branch"
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

export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init - bash)"

# Override terraform command to intercept apply operations
terraform() {
    local cmd="$1"
    
    # Check if this is an apply command (including variations)
    if [[ "$cmd" =~ ^apply$ ]] || [[ "$*" =~ terraform[[:space:]]+apply ]] || [[ "$*" =~ ^apply ]]; then
        
        # Define allowed account IDs - MODIFY THESE TO YOUR ACTUAL ACCOUNT IDS
        local allowed_accounts=("INSERT-AWS-ACCOUNT-ID-HERE")
        
        # Get current AWS account ID
        local current_account
        current_account=$(aws sts get-caller-identity --query Account --output text 2>/dev/null)
        
        if [[ $? -ne 0 ]] || [[ -z "$current_account" ]]; then
            echo "🚫 BLOCKED: Unable to determine current AWS account ID"
            echo "💡 Make sure AWS CLI is configured and you're authenticated"
            return 1
        fi
        
        # Check if current account is in allowed list
        local account_allowed=false
        for allowed in "${allowed_accounts[@]}"; do
            if [[ "$current_account" == "$allowed" ]]; then
                account_allowed=true
                break
            fi
        done
        
        if [[ "$account_allowed" == false ]]; then
            echo "🚫 BLOCKED: Current AWS account '$current_account' is not in the allowed list"
            echo "📋 Allowed accounts: ${allowed_accounts[*]}"
            echo "💡 To allow this account, add it to the allowed_accounts array in your shell profile"
            return 1
        fi
        
        echo "✅ Account '$current_account' verified. Running terraform apply..."
        command terraform "$@"
    else
        # For non-apply commands, pass through normally
        command terraform "$@"
    fi
}

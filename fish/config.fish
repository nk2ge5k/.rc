## ENV #######################################

fish_add_path -pP $HOME/.local/bin
fish_add_path -pP $HOME/.cargo/bin
fish_add_path -pP $HOME/bin
fish_add_path -pP $HOME/bin/go/bin
fish_add_path -pP $HOME/scripts/enabled/

set -gx LOG_LEVEL WARN
set -gx SHELL $(which fish)
set -gx EDITOR nvim
set -gx LANG "en_US.UTF-8"
set -gx LC_ALL "en_US.UTF-8"
set -gx LC_CTYPE "en_US.UTF-8"
set -gx GOPATH $HOME
set -gx LD_LIBRARY_PATH /usr/local/lib
set -gx FZF_DEFAULT_COMMAND "rg --files"
set -gx XDG_CONFIG_HOME $HOME/.config


## FUNCTIONS #################################

function _lvl_code --argument-names level
  set -l levels DEBUG INFO WARN ERROR
  set -l level $(string upper $level)

  for i in (seq 1 4)
    if test $levels[$i] = $level
      echo $i
      return
    end
  end

  echo 0
end

function plog --argument-names level message \
  -d 'Helper funcation that allows to print formatted log messages'
  if not set -q LOG_LEVEL
    return
  end

  set -l base_level $(string upper $LOG_LEVEL)
  set -l base_level_code $(_lvl_code $base_level)

  set -l log_level $(string upper $level)
  set -l log_level_code $(_lvl_code $log_level)

  if test $log_level_code -lt $base_level_code
    return
  end

  switch $log_level
    case DEBUG
      set_color brblack
    case INFO
      set_color green
    case WARN
      set_color yellow
    case ERROR
      set_color red
    case '*'
  end 

  echo -n "$log_level"; set_color normal;
  echo -n " [$(date '+%Y-%m-%d %H:%M:%S')] "
  echo "$message"
end

function logd --argument-names message -d 'Logs message with DEBUG level'
  plog DEBUG $message
end

function logi --argument-names message -d 'Logs message with INFO level'
  plog INFO $message
end

function logw --argument-names message -d 'Logs message with WARN level'
  plog WARN $message
end

function loge --argument-names message -d 'Logs message with ERROR level'
  plog ERROR $message
end

function d -d 'Changes directory to the root of current get repository'
  set start_directory $PWD
  while test $PWD != "/"
    if test -d .git
      break
    end
    cd ..
  end

  if test $PWD = "/"
    cd $start_directory
  end
end

function _smux_new_session --argument-names name
  eval "tmux new-session -d -s $name -n $name"
end

function smux --argument-names session_name space_path \
  -d 'Creates TMUX workspace and session at given path'
  if not file $space_path > /dev/null
    loge "No such file or drectory: $space_path"
    return
  end

  set -l space_name $(basename $space_path)
  if not tmux has-session -t $session_name &> /dev/null
    _smux_new_session $session_name
  end

  if not test $(tmux list-windows -a -F'#S:#W' | grep -w "$session_name:$space_name")
    eval "tmux neww -t $session_name -n $space_name -c $space_path -a"
  end

  if not set -q TMUX
    eval "tmux attach"
  else
    eval "tmux switch-client -t '$session_name:$space_name'"
  end
end

function session -d 'Start session from ~/.projects config'
  set -l choice $(cat ~/.projects | fzf)
  set -l parts $(string split ' ' $choice)

  if test -z $choice
    return
  end

  if test $(count $parts) -eq 3
    set -l type $parts[1]
    set -f directory $parts[2]
    set -l session_name $parts[3]
    switch $type
      case +
      case '*'
        set -l name $(eval "ls $directory" | fzf)
        if test -z $name
          return
        end

        set -f directory "$directory/$name"
    end
    smux $session_name $directory
  else
    smux "scratch" $parts[1]
  end
end

function src --argument-names repository -d 'Clone given git repository'
  set -l vendor_path $(dirname repository)
  eval "mkdir -p ~/src/$vendor_path"
  eval "git clone https://$repository.git ~/src/$repository"
end


if status is-interactive
  set fish_greeting

## KEYBINDINGS ###############################
  bind \cx\ce edit_command_buffer
  bind \cx\cs session

## GPG #######################################

  if command -v gpgconf > /dev/null
    set -gx GPG_TTY (tty)
    gpgconf --launch gpg-agent
  end

## SSH #######################################

  if command -v ssh-agent > /dev/null
    # eval ssh-agent > /dev/null
    if test (uname) = "Darwin"
      ssh-add --apple-use-keychain 2> /dev/null
    end
  end

## ALIASES ###################################

  if command -v nvim > /dev/null
    abbr -a vim 'nvim'
  end

  if command -v exa > /dev/null
    abbr -a l 'exa'
    abbr -a ls 'exa'
    abbr -a ll 'exa -l'
    abbr -a lll 'exa -la'
  else
    abbr -a l 'ls'
    abbr -a ll 'ls -l'
    abbr -a lll 'ls -la'
  end

end

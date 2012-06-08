#
# THIS FILE IS MANAGED BY PUPPET. DO NOT EDIT
# AR SOFT PUPPET CONFIG
#
# System-wide .bashrc file for interactive bash(1) shells.

# To enable the settings / commands in this file for login shells as well,
# this file has to be sourced in /etc/profile.

# If not running interactively, don't do anything
[ -z "$PS1" ] && return

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "$debian_chroot" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# set a fancy prompt (non-color, overwrite the one in /etc/profile)
PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '

# Commented out, don't overwrite xterm -T "title" -n "icontitle" by default.
# If this is an xterm set the title to user@host:dir
#case "$TERM" in
#xterm*|rxvt*)
#    PROMPT_COMMAND='echo -ne "\033]0;${USER}@${HOSTNAME}: ${PWD}\007"'
#    ;;
#*)
#    ;;
#esac

# enable bash completion in interactive shells
#if [ -f /etc/bash_completion ] && ! shopt -oq posix; then
#    . /etc/bash_completion
#fi

# sudo hint
if [ ! -e "$HOME/.sudo_as_admin_successful" ] && [ ! -e "$HOME/.hushlogin" ] ; then
    case " $(groups) " in *\ admin\ *)
    if [ -x /usr/bin/sudo ]; then
	cat <<-EOF
	To run a command as administrator (user "root"), use "sudo <command>".
	See "man sudo_root" for details.
	
	EOF
    fi
    esac
fi

# if the command-not-found package is installed, use it
if [ -x /usr/lib/command-not-found -o -x /usr/share/command-not-found/command-not-found ]; then
function command_not_found_handle {
	# check because c-n-f could've been removed in the meantime
	if [ -x /usr/lib/command-not-found ]; then
		/usr/bin/python /usr/lib/command-not-found -- "$1"
		return $?
	elif [ -x /usr/share/command-not-found/command-not-found ]; then
		/usr/bin/python /usr/share/command-not-found/command-not-found -- "$1"
		return $?
	else
		return 127
	fi
}
fi

export PATH
#
# Colored file listings
#
if test -x /usr/bin/dircolors ; then
	#
	# set up the color-ls environment variables:
	#
	if test -f $HOME/.dir_colors ; then
		eval `dircolors -b $HOME/.dir_colors`
	elif test -f /etc/DIR_COLORS ; then
		eval `dircolors -b /etc/DIR_COLORS`
	fi
fi

#
# ls color option depends on the terminal
# If LS_COLROS is set but empty, the terminal has no colors.
#
if [ "${LS_COLORS+empty}" = "${LS_COLORS:+empty}" ]; then
    LS_OPTIONS='--color=auto'
else
    LS_OPTIONS='--color=none'
fi
if [ $UID -eq 0 ]; then
    LS_OPTIONS="-a -N $LS_OPTIONS -T 0"
else
    LS_OPTIONS="-N $LS_OPTIONS -T 0"
fi

alias ls="/bin/ls $LS_OPTIONS"
export LS_OPTIONS

alias cd..="cd .."
alias ..="cd .."
alias ..2="cd ../.."
alias ..3="cd ../../.."
alias ..4="cd ../../../.."
alias ..5="cd ../../../../.."

function mkdircd () { mkdir -p "$@" && eval cd "\"\$$#\""; }

# ignore from trival commands from history
export HISTIGNORE="&:ls:[bf]g:exit"
# limit the number of commands rememberd by bash to 300
export HISTSIZE=300
export HISTFILESIZE=300
# don't put duplicate lines in the history and ignore same sucessive entries.
export HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

#
# End of /etc/bash.bashrc
#

#!/bin/builder.sh
skip=( false false false false )
step=3
prefix="setup"
source="https://raw.github.com/michaelsalisbury/builder/master/defaults/${scriptName}"
#source=http://10.173.119.78/scripts/system-setup/$scriptName

#function includes(){
#	functions.*.sh
#	../functions/functions.*.sh
#}

# GLOBAL VARIABLES
#function global_variables(){
#	echo
#}

function setup_Create_Systemwide_Defaults(){
	desc Write /etc/vim/vimrc.local
	touch     /etc/skel/.viminfo
	chmod 600 /etc/skel/.viminfo
	cat <<-END-OF-VIMRC > /etc/vim/vimrc.local
		"http://vim.wikia.com/wiki/Xterm256_color_names_for_console_Vim
		"zf#j creates a fold from the cursor down # lines.
		"zf/string creates a fold from the cursor to string .
		"zj moves the cursor to the next fold.
		"zk moves the cursor to the previous fold.
		"zo opens a fold at the cursor.
		"zO opens all folds at the cursor.
		"zm increases the foldlevel by one.
		"zM closes all open folds.
		"zr decreases the foldlevel by one.
		"zR decreases the foldlevel to zero -- all folds will be open.
		"zd deletes the fold at the cursor.
		"zE deletes all folds.
		"[z move to start of open fold.
		"]z move to end of open fold.

		" set file extension .sh to syntax bash
		:let is_bash		=1
		" enable function folding
		:let sh_fold_enabled	=1
		:set foldmethod		=syntax
		:let foldnestmax	=1
		:let foldlevel		=1
		:set nofoldenable
		"highlight Folded  ctermbg=none
		"highlight Folded  cterm=underline
		highlight Folded  ctermbg=darkgrey 
		highlight Folded  ctermfg=cyan
		highlight Folded  cterm=none 

		" Change comment highlighting from dark blue to dark green
		highlight Comment ctermfg=DarkGreen

		" enable highlight searching
		:set hlsearch

		" Do not wrap text
		:set nowrap!

		" Toggle word wrap by pressing F2
		:map <F2> :set nowrap! <CR>

		if has("autocmd")
		  " When editing a file, always jump to the last cursor position
		  autocmd BufReadPost *
		  \ if line("'\"") > 0 && line ("'\"") <= line("$") |
		  \   exe "normal! g'\"" |
		  \ endif
		  " don't write swapfile on most commonly used directories for NFS mounts or USB sticks
		  autocmd BufNewFile,BufReadPre /media/*,/mnt/* set directory=~/tmp,/var/tmp,/tmp
		endif
	END-OF-VIMRC
}

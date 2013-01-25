

function one(){
	echo one :: ${BASH_SOURCE}
	two
}
function two(){
	echo two :: ${BASH_SOURCE}
	three
}
function three(){
	echo three :: ${BASH_SOURCE} :: ${#FUNCNAME[@]} :: ${FUNCNAME[@]}
}
echo base :: ${BASH_SOURCE}
one

















exit 1

if read -a results < <(df -T | grep /locks); then
	echo ${results[@]: -1}
elif read -a results < <(df -T | grep /shm); then
	echo ${results[@]: -1}
else
	echo /tmp

fi
















exit 1

cnt=0
IFS=$'\n'
while read -d $'\@' -a line; do
	let cnt+=1
	echo $cnt :: $line

done < <(sed '1h;1!H;$!d;$g' <(cat << EOF
one
two
three
EOF
))

unset IFS

read -a bob < <(echo one two three)
echo ${#bob[@]} :: ${bob[0]} :: ${bob[1]} :: ${bob[2]}
unset bob

IFS=$'\n'
read -d $'' -a bob << EOF
line-one sam
line-two
line-three
EOF
for l in ${bob[@]}; do echo -n $l ::\ ; done; echo ${#bob[@]}
unset bob
unset IFS



IFS=$'\n'
read -d $'' -a bob < <(sed '1h;1!H;$!d;$g' <(cat << EOF
1-one
2-two
3-three
EOF
))
for l in ${bob[@]}; do echo -n $l ::\ ; done; echo ${#bob[@]}
unset bob
unset IFS


IFS=$'\n'
read -d $'' -a bob < <(sed '/^$/s/$/\n\n/;1h;1!H;$!d;$g' data)
for l in ${bob[@]}; do echo -n $l ::\ ; done; echo ${#bob[@]}
bob="${bob[@]/#/$'\n'}"
bob=${bob:1}
echo "${bob}"
unset bob
unset IFS





exit 0

function git_isintree(){
	local file=$1
	local git_search_results_cnt=`git	\
		--work-tree="${rootPath}"       \
		--git-dir="${rootPath}/.git"    \
		ls-tree                         \
                --name-only                     \
                HEAD				\
		"${file}"			|\
		wc -l`
	if (( git_search_results_cnt > 0 ))
	then
		return 0
	else
		return 1
	fi 
}
function git_add(){
	local file=$1
	if ! git_isintree "${file}"; then
		echo hi
		return 0
		git				\
		--work-tree="${rootPath}"       \
		--git-dir="${rootPath}/.git"    \
		add "${file}"
	fi
}

testTarget=/var/www/repos/github/michaelsalisbury_builder/tmp/test.py3
#testTarget=/var/www/repos/github/michaelsalisbury_builder/tmp/test.sh
rootPath=/var/www/repos/github/michaelsalisbury_builder


git_add "${testTarget}"

exit 0
		git				\
		--work-tree="${rootPath}"       \
		--git-dir="${rootPath}/.git"    \
		commit -a --allow-empty-message -m ''


		git				\
		--work-tree="${rootPath}"       \
		--git-dir="${rootPath}/.git"    \
		push






##
# Renames selected files according to a given pattern.
#
# Usage:
#    renume [options] <pattern> <file> [<file>...]
#
# Example:
#    renume.sh -t 201709181700.@i -p '20170918-MyFile-@i.png' *
#
# Options:
#
# -p PATTERN - pattern can contain placeholders replaced during renume; default is '@i-@n'
# -t TIME_PATTERN - if specified, time can be changed to specified one (can contain order placeholder!)
#
# Placeholders:
#
# @i - replaced with order (2 digits by default)
# @n - original name


#### GLOBALS ####

PATTERN="@i-@n"
TOUCH_TIME=""

function applyPattern() {
	local pattern=$1
	local i=$2
	local file=$3
	local result=${pattern/@i/$i}
	result=${result//@n/$file}
	echo "$result"
}

function main() {
	while [ "${1:0:1}" == "-" ]; do
		opt=$1
		shift
		case "$opt" in
		'-p') PATTERN=$1; shift;;
		'-t') TOUCH_TIME=$1; shift;;
		*) echo "ERROR: Unsupported option: $opt" >&2; exit;;
		esac
	done

	echo "PATTERN=$PATTERN"
    local order=0
    local file
    for file in "$@"; do
        order=$(( order + 1 ))
        local i=$(printf "%02d" "$order")
        local newName=$(applyPattern "$PATTERN" "$i" "$file")
        if [ "$file" != "$newName" ]; then
            mv -v "$file" "$newName" || break
        fi
        if [ -n "$TOUCH_TIME" ]; then
            local timestamp=$(applyPattern "$TOUCH_TIME" "$i" "$file")
            touch -t "$timestamp" "$newName" || break
        fi
    done
}

#### MAIN ####
main "$@"


# TODO: if there is no order placeholder in pattern, add one at the beginning

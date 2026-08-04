#!/usr/bin/bash

test -v bashutils_sourced && return
declare -r bashutils_version='1.0.0'
declare bashutils_bash_source
declare -i bashutils_line_number
declare bashutils_function_name
declare -i bashutils_return_code
declare bashutils_stdout_path
declare bashutils_stderr_path
declare -a bashutils_commands
declare -a bashutils_temp_paths
declare -a bashutils_errors
declare -a bashutils_errors_snapshot
declare -i bashutils_fd_id=3
declare -ir bashutils_variable_true=1
declare -ir bashutils_variable_false=0
declare -ir bashutils_function_true=0
declare -ir bashutils_function_false=1
declare -r bashutils_sourced

heredoc() {
	parameter_count 1 "$@"
	declare $ref_opt variable_ref=$1
    read -r -d '' variable_ref
	variable_ref+=$'\n'
}



# gpg --batch --passphrase-fd 3 
# 
# printf '%s\n' "$password" | sudo -S command



# declare -i string_length_variable
# get_string_length string_variable string_length_variable 

get_string_length() {
	parameter_count 2 "$@"
	declare -n string_ref="$1"
	declare -n length_ref="$2"
	length_ref=${#string_ref}
}

# declare bashutils_password
# execute_command_prompt prompt_password bashutils_password prompt_value

prompt_password() {
	parameter_count 1 "$@"
	declare -n password_ref="$1"
	declare prompt_line="$2"
	declare bashutils_password
	execute_command_prompt read -r -s -p "$prompt_line" bashutils_password
	execute_command_prompt echo
}

# check_password bashutils_password

check_password() {

	declare -i bashutils_password_length
	get_string_length bashutils_password bashutils_password_length

	LC_ALL=C
	check_condition_sensetive_error "Password contains invalid characters" [[ "$password" =~ ^[ -~]+$ ]]
	check_condition_error "Password containes less than 12 characters" [[ $bashutils_password_length -lt 12 ]]
	check_condition_sensetive_error "Password does NOT contain lower case letters" [[ "$password" =~ [a-z] ]]
	check_condition_sensetive_error "Password does NOT contain upper case letters" [[ "$password" =~ [A-Z] ]]
	check_condition_sensetive_error "Password does NOT contain numbers" [[ "$password" =~ [0-9] ]]
	check_condition_sensetive_error "Password does NOT contain symbols" [[ "$password" =~ [^a-zA-Z0-9] ]]
}







# create_password_file password_value

create_password_file() {
	parameter_count 1 "$@"
	declare bashutils_password="$1"
	exec $bashutils_fd_id<<< "$bashutils_password"
	(( bashutils_fd_id++ ))
}

# exec 3<<< printf 'user = "%s:%s"\n' "$user_name" "$password"
# exec 3<<-EOF
# user = "${user}:${password}"
# EOF
# curl --config /dev/fd/3 https://api.example.com
# exec 3<<< printf '%s' "$password"
# mkpasswd --stdin <&3




# if last word is ]] , its a regex condition and masked 1 word before ( =~ ) sign


mask_command_line() {
    declare -n masked_ref=$1
    declare command_line="$2"
    local last="${command_line##* }"         # Get last word
    local rest="${command_line% *}"          # Everything except last word
    masked_ref="${rest% *} ******** $last"   # Mask new last word of rest
}


mask_command_line() {
    declare -n masked_ref=$1
    declare command_line="$2"
    
    # Get last word and everything before it
    local last_word="${command_line##* }"
    local without_last="${command_line% *}"
    
    # Mask the new last word of the remaining string
    masked_ref="${without_last% *} ******** $last_word"
}











# if last word was ]] or )) , mask 1 index before

# mask_command_line command_line_masked_variable "$*"

mask_command_line() {
	parameter_count 2 "$@"
	declare -n masked_ref=$1
	declare command_line="$2"
	masked_ref="${command_line% *} ********"
}

# log_command "$*"

log_command() {
	parameter_count 1 "$@"
	append_list_elements bashutils_commands "$1"
}

# log_command_sensetive "$*"

log_command_sensetive() {
	parameter_count 1 "$@"
	declare command_line_masked
	mask_command_line command_line_masked "$1"
	log_command "$command_line_masked"
}

# create_temp_path temp_path_variable

create_temp_path() {
	parameter_count 1 "$@"
	declare $ref_opt path_ref=$1
	path_ref=$(mktemp)
	append_list_elements bashutils_temp_paths $path_ref
}

# get_errors_snapshot

get_errors_snapshot() {
	copy_list bashutils_errors bashutils_errors_snapshot
}

# set_errors_snapshot || return $function_false

set_errors_snapshot() {
	copy_list bashutils_errors_snapshot bashutils_errors
}

# get_execution_context

get_execution_context() {
	declare $int_opt nest_level
	for_each_function() {
		(( list_index > 0 )) && \
		[[ "$list_element" != execute_command* && "$list_element" != run_command_* && "$list_element" != check_condition* ]] && {
			nest_level=$list_index
			break_loop
		}
	}
	for_loop FUNCNAME for_each_function
	get_list_element FUNCNAME $nest_level bashutils_function_name
	get_list_element BASH_SOURCE $nest_level bashutils_bash_source
	get_list_element BASH_LINENO $(( nest_level - 1 )) bashutils_line_number
	create_temp_path bashutils_stdout_path
	create_temp_path bashutils_stderr_path
}

# log_error "$*"

log_error() {
	bashutils_return_code=$?
	parameter_count 1 "$@"
	declare bashutils_command_line="$1"
	declare bashutils_error_entry
	declare bashutils_error_timestamp="$(date -u +'%Y/%m/%d %H:%M:%S')"
	declare bashutils_standard_output=$(<"$bashutils_stdout_path")
	declare bashutils_standard_error=$(<"$bashutils_stderr_path")
	heredoc bashutils_error_entry <<-EOF
		Time Stamp      : $bashutils_error_timestamp
		Script Name     : $bashutils_bash_source
		Line Number     : $bashutils_line_number
		Function Name   : $bashutils_function_name
		Command Line    : $bashutils_command_line
		Return Code     : $bashutils_return_code
		Standard Output : $bashutils_standard_output
		Standard Error  : $bashutils_standard_error
	EOF
	append_list_elements bashutils_errors_list bashutils_error_entry
}

# log_error_message error_message_value "$*"

log_error_message() {
	bashutils_return_code=$?
	parameter_count 2 "$@"
	declare bashutils_script_error="$1"
	declare bashutils_command_line="$2"
	declare bashutils_error_entry
	declare bashutils_error_timestamp="$(date -u +'%Y/%m/%d %H:%M:%S')"
	declare bashutils_standard_output=$(<"$bashutils_stdout_path")
	declare bashutils_standard_error=$(<"$bashutils_stderr_path")
	heredoc bashutils_error_entry <<-EOF
		Time Stamp      : $bashutils_error_timestamp
		Script Name     : $bashutils_bash_source
		Line Number     : $bashutils_line_number
		Function Name   : $bashutils_function_name
		Command Line    : $bashutils_command_line
		Return Code     : $bashutils_return_code
		Standard Output : $bashutils_standard_output
		Standard Error  : $bashutils_standard_error
		Script Error    : $bashutils_script_error
	EOF
	append_list_elements bashutils_errors_list bashutils_error_entry
}

# execute_command "$@"

execute_command() {
	parameter_count_minimum 1 "$@"
	get_execution_context
	"$@" 1>$bashutils_stdout_path 2>$bashutils_stderr_path || log_error "$*"
	return $bashutils_return_code
}

# execute_command_prompt

execute_command_prompt() {
	parameter_count_minimum 1 "$@"
	get_execution_context
	"$@" || log_error "$*"
	return $bashutils_return_code
}

# execute_command_sensetive "$@"

execute_command_sensetive() {
	parameter_count_minimum 1 "$@"
	declare command_line_masked
	mask_command_line command_line_masked "$*"
	get_execution_context
	"$@" 1>$bashutils_stdout_path 2>$bashutils_stderr_path || log_error "$command_line_masked"
	return $bashutils_return_code
}

# execute_command_error error_message_value "$@"

execute_command_error() {
	parameter_count_minimum 2 "$@"
	declare bashutils_script_error="$1"
	shift 
	get_execution_context
	"$@" 1>$bashutils_stdout_path 2>$bashutils_stderr_path || log_error "$bashutils_script_error" "$*"
	return $bashutils_return_code
}

# execute_command_sensetive_error error_message_value "$@"

execute_command_sensetive_error() {
	parameter_count_minimum 2 "$@"
	declare bashutils_script_error="$1"
	shift
	declare command_line_masked
	mask_command_line command_line_masked "$*"
	get_execution_context
	"$@" 1>$bashutils_stdout_path 2>$bashutils_stderr_path || log_error "$bashutils_script_error" "$command_line_masked"
	return $bashutils_return_code
}



# run_command_handler : case return code x -> do y based on execute_command

# run_command command_line_value

run_command() {
	parameter_count_minimum 1 "$@"
	log_command "$*"
	execute_command "$@"
}

# run_command_error error_message_value command_line_value

run_command_error() {
	parameter_count_minimum 2 "$@"
	declare bashutils_script_error="$1"
	shift
	log_command "$*"
	execute_command_error "$bashutils_script_error" "$@"
}

# run_command_sensetive command_line_value

run_command_sensetive() {
	parameter_count_minimum 1 "$@"
	log_command_sensetive "$*"
	execute_command_sensetive "$@"
}

# run_command_sensetive_error error_message_value command_line_value

run_command_sensetive_error() {
	parameter_count_minimum 2 "$@"
	declare bashutils_script_error="$1"
	shift
	log_command_sensetive "$*"
	execute_command_sensetive_error "$bashutils_script_error" "$@"
}

# check_condition_required condition_line

check_condition() {
	parameter_count_minimum 1 "$@"
	execute_command "$@" || return 1
}

# check_condition_required_inverted condition_line

check_condition_inverted() {
	parameter_count_minimum 1 "$@"
	! execute_command "$@"
}

# check_condition_required_sensetive condition_line

check_condition_sensetive() {
	parameter_count_minimum 1 "$@"
	execute_command_sensetive "$@" || return 1
}

# check_condition_required_error error_message_value condition_line

check_condition_error() {
	parameter_count_minimum 2 "$@"
	declare bashutils_script_error="$1"
	shift
	execute_command_error "$bashutils_script_error" "$@" || return 1
}

# check_condition_required_sensetive_error error_message_value condition_line

check_condition_sensetive_error() {
	parameter_count_minimum 2 "$@"
	declare bashutils_script_error="$1"
	shift
	execute_command_sensetive_error "$bashutils_script_error" "$@" || return 1
}





























check_condition() {
	parameter_count_minimum 1 "$@"
	declare $list_opt bashutils_commands_snapshot
	copy_list bashutils_commands bashutils_commands_snapshot
	declare $list_opt bashutils_errors_snapshot
	copy_list bashutils_errors bashutils_errors_snapshot
	if execute_command "$@"
	then
		copy_list bashutils_commands_snapshot bashutils_commands
		copy_list bashutils_errors_snapshot bashutils_errors
	else
		return $bashutils_return_code
	fi
}






# declare $int_opt conditions_status condition
# check_condition_required conditions_status condition

check_condition_required() {
	parameter_count_minimum 2 "$@"
	declare $ref_opt status_ref=$1
	shift
	[[ -z "$status_ref" ]] && status_ref=$function_true
	(( status_ref == function_true )) && {
		check_condition "$@" || status_ref=$function_false 
	}
}

# check_condition_required_inverted conditions_status condition

check_condition_required_inverted() {
	parameter_count_minimum 2 "$@"
	declare $ref_opt status_ref=$1
	shift
	[[ -z "$status_ref" ]] && status_ref=$function_true
	(( status_ref == function_true )) && {
		check_condition_inverted "$@" || status_ref=$function_false 
	}
}

# check_condition_required_error conditions_status error_message condition

check_condition_required_error() {
	parameter_count_minimum 3 "$@"
	declare $ref_opt status_ref=$1
	shift
	declare script_error="$2"
	shift
	[[ -z "$status_ref" ]] && status_ref=$function_true
	(( status_ref == function_true )) && {
		check_condition_error "$script_error" "$@" || {
			status_ref=$function_false 
		}
	}
}

# check_condition_required_inverted_error conditions_status error_message condition

check_condition_required_inverted_error() {
	parameter_count_minimum 3 "$@"
	declare $ref_opt status_ref=$1
	shift
	declare script_error="$2"
	shift
	[[ -z "$status_ref" ]] && status_ref=$function_true
	(( status_ref == function_true )) && {
		check_condition_inverted_error "$script_error" "$@" || {
			status_ref=$function_false 
		}
	}
}

# check_condition_sufficient conditions_status condition

check_condition_sufficient() {
	parameter_count_minimum 2 "$@"
	declare $ref_opt status_ref=$1
	shift
	[[ -z "$status_ref" ]] && status_ref=$function_false
	(( status_ref == function_false )) && {
		check_condition "$@" && status_ref=$function_true
	}
}

# check_condition_sufficient_inverted conditions_status condition

check_condition_sufficient_inverted() {
	parameter_count_minimum 2 "$@"
	declare $ref_opt status_ref=$1
	shift
	[[ -z "$status_ref" ]] && status_ref=$function_false
	(( status_ref == function_false )) && {
		check_condition "$@" || status_ref=$function_true
	}
}

# check_conditions conditions_status

check_conditions() {
	parameter_count 1 "$@"
	declare $int_opt function_code=$1
	(( function_code == function_true )) && {
		return $function_true
	} || {
		return $function_false
	}
}

# check_conditions_error conditions_status error_message

check_conditions() {
	parameter_count 2 "$@"
	declare $ref_opt code_ref=$1
	declare script_error="$2"
	(( code_ref == function_true )) && {
		return $function_true
	} || {
		append_list_elements bashutils_errors_list "$script_error"
		return $function_false
	}
}



bashutils_error_handler() {}



trap bashutils_error_handler ERR








FINAL WAY :
==================================================================


declare -a bashutils_error_stack=()

add_error() {
	bashutils_error_stack+=("[${FUNCNAME[1]:-main}] $1")
}

# This will exit on failure because of set -e
expect_error() {
	local error_message="$1"
	shift
	"$@" 2>/dev/null || {
		add_error "$error_message"
		false  # Triggers set -e
	}
}

# ERR trap shows the stack
error_handler() {
	local exit_code=$?
	echo "=== Error Stack (exit code: $exit_code) ===" >&2
	if (( ${#bashutils_error_stack[@]} > 0 )); then
		for i in "${!bashutils_error_stack[@]}"; do
			echo "  $((i+1)). ${bashutils_error_stack[i]}" >&2
		done
	else
		echo "  (no error messages collected)" >&2
	fi
	echo "==========================================" >&2
	exit $exit_code
}

trap error_handler ERR

is_file_readable() {
	[[ -r "$1" ]]
}

set_file_readable() {
	local file_path="$1"
	
	is_file_readable "$file_path" && return 0
	
	# No || return 1 needed - set -e handles it
	expect_error "file does not exist: $file_path" test -e "$file_path"
	expect_error "failed to make file readable: $file_path" chmod +r "$file_path"
}

read_conf_file() {
	local conf_file="$1"
	
	expect_error "cannot access config file: $conf_file" set_file_readable "$conf_file"
	expect_error "failed to parse config: $conf_file" source "$conf_file"
}

init_application() {
	local conf_dir="$1"
	
	expect_error "application initialization failed" read_conf_file "$conf_dir/app.conf"
}

main() {
	init_application "/etc/myapp"
	echo "Application started successfully"
}

main

==================================================================




















# parameter_count 1 "$@"

parameter_count() {
	true_condition=$(($# >= 2))
	expect_error "function ( parameter_count ) requires at least 2 parameters" [[ $true_condition ]]
	expect_error "function ( parameter_count ) first parameter ( $1 ) should be a positive number" is_value_integer_natural "$1"
	declare "$integer_opt" target_parameter_count=$1
	declare "$integer_opt" parameter_count=$#
	parameter_count=$(( parameter_count - 1 ))
	true_condition=$(( parameter_count == target_parameter_count ))
	declare "$string_opt" parent_function_name="${FUNCNAME[1]}"
	expect_error "function ( ${parent_function_name} ) requires ${target_parameter_count} parameter(s)" [[ $true_condition ]]
}

# parameter_count_minimum 1 "$@"

parameter_count_minimum() {
	true_condition=$(($# >= 2))
	expect_error "function ( parameter_count ) requires at least 2 parameters" [[ $true_condition ]]
	expect_error "function ( parameter_count ) first parameter ( $1 ) should be a positive number" is_value_integer_natural "$1"
	declare "$integer_opt" minimum_parameter_count=$1
	declare "$integer_opt" parameter_count=$#
	parameter_count=$(( parameter_count - 1 ))
	true_condition=$(( parameter_count >= minimum_parameter_count ))
	declare "$string_opt" parent_function_name="${FUNCNAME[1]}"
	expect_error "function ( ${parent_function_name} ) requires at least ${target_parameter_count} parameter(s)" [[ $true_condition ]]
}

# ||||||||||||||||| FINAL PATTERN ||||||||||||||||||||||||||| 


# expect_error "variable ( $1 ) is not declared" is_variable_declared "$1"

# is_variable_declared variable_name

is_variable_declared() {
	parameter_count 1 "$@"
	[[ -v "$1" ]]
}

# get_variable_type variable_name variable_type

get_variable_type() {
	parameter_count 2 "$@"
	declare "$string_opt" variable_name="$1"
	declare "$reference_opt" type_reference="$2"
	declare "$string_opt" variable_declaration
	variable_declaration="$(declare -p "$variable_name" 2>/dev/null)"
	declare "$list_opt" variable_types
	append_list_elements variable_types string integer list dictionary
	declare "$list_opt" declaration_regexes
	append_list_elements declaration_regexes '[^[:space:]aAi]*' '[^[:space:]]*i' '[^[:space:]]*a' '[^[:space:]]*A'
	for_each_declaration_regex() {
		declare "$string_opt" declaration_regex
		declaration_regex='^declare[[:space:]]-'"$list_element"'[[:space:]]'
		if [[ "$variable_declaration" =~ $declaration_regex ]]
		then
			get_list_element variable_types $list_index type_reference
			break_loop
		fi
	}
	for_loop declaration_regexes for_each_declaration_regex
}

# is_variable_type { string | integer | list | dictionary } variable_name

is_variable_type() {

}













# is_value_integer integer_value ( -1 : true , 0 : true , 1 : true )

is_value_integer() {
	parameter_count 1 "$@"
	expect_error "value ( $1 ) is not an integer" [[ "$1" =~ ^-?[0-9]+$ ]]
}

# is_value_integer_whole integer_value ( -1 : false , 0 : true , 1 : true ) 

is_value_integer_whole() {
	parameter_count 1 "$@"
	expect_error "value ( $1 ) is not a whole number" [[ "$1" =~ ^[0-9]+$ ]]
}

# is_vlaue_integer_natural integer_value ( -1 : false , 0 : false , 1 : true ) 

is_value_integer_natural() {
	parameter_count 1 "$@"
	expect_error "value ( $1 ) is not a natural number" [[ "$1" =~ ^[1-9][0-9]*$ ]]
}

# is_value_boolean boolean_value

is_value_boolean() {
	parameter_count 1 "$@"
	expect_error "value ( $1 ) is not a boolean" [[ "$1" =~ ^[01]$ ]]
}



# is_value_assigned value 

is_value_assigned() {
	parameter_count 1 "$@"
	expect_error "variable ( $1 ) is not assigned" [[ -n "$1" ]]
}


: <<'EOF'
declare "$list_opt" function_name_conditions
add_true_condition function_name_conditions condition
add_false_condition function_name_conditions condition
EOF









# is_string variable_name

is_string() {
	parameter_count 1 "$@"
	declare "$reference_opt" variable_reference="$1"
	declare "$list_opt" is_string_true_conditions
	is_variable_declared "$1"
	append_list_elements is_string_true_conditions $?
	is_value_assigned "$variable_reference"
	append_list_elements is_string_true_conditions $?

}

# is_integer variable_name

is_integer_() {}




is_list_assigned() {
	[[ -v "$1" && -v "${1}[0]" ]]
}

-n "${array[0]}"

# -n ( value )
# ref then -n ( variable )

is_scalar_variable_assigned() {

}

# ${#var[@]} -gt 0

is_list_assigned


# is_value_list ???

# is variable_assigned variable_name



# append_string variable_name string_value

append_string() {
	parameter_count 2 "@"
	delare $ref_opt variable_ref=$1
	declare string_suffix="$2"
	variable_ref+="$string_suffix"
}

# copy_list list_name dest_variable

copy_list() {
	parameter_count 2 "$@"
	declare $ref_opt list_ref=$1
	declare $ref_opt dest_variable_ref=$2
	dest_variable_ref=("${list_ref[@]}")
}

# get_list_element list_name list_index list_element

get_list_element() {
	parameter_count 3 "$@"
	declare "$reference_opt" list_reference=$1
	declare "$integer_opt" list_index=$2
	declare "$reference_opt" element_reference=$3
	element_reference=${list_reference[list_index]}
}

# is_list_element list_name value

is_list_element() {
	parameter_count 2 "$@"
	declare "$string_opt" list_name=$1
	declare "$string_opt" input_value=$2
	declare "$boolean_opt" return_code=$function_false 
	for_each_value() {
		if [[ "$list_element" == "$input_value" ]]
		then
			return_code=$function_true
			break_loop
		fi
	}
	for_loop $list_name for_each_value
	return $return_code
}

# get_list_length list_name list_length

get_list_size() {
	parameter_count 2 "$@"
	declare "$reference_opt" list_reference="$1"
	declare "$reference_opt" list_length="$2"
	list_length=${#list_reference[@]}
}

# is_length_same list_1_name list_2_name

are_lists_same_size() {
	parameter_count 2 "$@"
	declare list_1_name=$1
	declare list_2_name=$2
	declare $int_opt list_1_length
	declare $int_opt list_2_length
	get_list_size $list_1_name list_1_length
	get_list_size $list_2_name list_2_length
	(( list_1_length != list_2_length )) && return 1
}

# are_lists_same list_1_name list_2_name

are_lists_same() {
	parameter_count 2 "$@"
	declare list_1_name=$1
	declare list_2_name=$2
	are_lists_same_size $list_1_name $list_2_name
	declare $int_opt are_same=$function_true
	for_each_element() {
		declare list_2_element
		get_list_element $list_2_name $list_index list_2_element 
		[[ "$list_element" != "$list_2_element" ]] && {
			are_same=$function_false
			break_loop
		}
	}
	for_loop $list_1_name for_each_element
	(( are_same == function_false )) && return 1
}

# append_list_elements list_name list_element_value ...

append_list_elements() {
	parameter_count_minimum 2 "$@"
	declare "$reference_opt" list_reference="$1"
	shift
	list_reference+=("$@")
}

break_loop() {
	loop_break_reference=$variable_true
}

for_loop() {
	declare "$reference_opt" list_reference="$1"
	declare "$string_opt" function_name="$2"
	declare "$integer_opt" loop_break=$variable_false
	declare "$integer_opt" list_index
	for list_index in "${!list_reference[@]}"
	do
		declare "$reference_opt" list_element="list_reference[$list_index]"
		declare "$reference_opt" loop_break_reference=loop_break
		$function_name
		(( loop_break == $variable_false )) || {
			break
		}
	done
}

for_loop_reverse() {
	declare "$reference_opt" list_reference=$1
	declare "$string_opt" function_name=$2
	declare "$integer_opt" loop_break=$variable_false
	declare "$integer_opt" list_index
	declare "$string_opt" list_name=$1
	declare "$integer_opt" list_length
	get_list_length $list_name list_length
	for (( list_index=list_length - 1 ; list_index >= 0 ; list_index-- ))
	do
		declare "$reference_opt" list_element="list_reference[$list_index]"
		declare "$reference_opt" loop_break_reference=loop_break
		$function_name
		(( loop_break == $variable_false )) || {
			break
		}
	done
}










# undefined_function() { :; }
# assign_integer
# assign_list variable_name 'abc' 'xyz'







: <<'EOF'

#!/bin/bash
set -Eeuo pipefail

=== Syntax :

declare    : string variable
declare -l : lower case string variable
declare -u : upper case string variable
declare -i : integer variable
declare -a : list variable ( bash indexed array )
declare -A : dictionary variable ( bash associative array )
declare -n : nameref variable
declare -g : global variable
declare -x : exported variable
declare -r : readonly variable

=== Heredoc : ( TAB Indentation )

heredoc variable_name <<-EOF
	value
 	$variable_name
# EOF

[[ string == string ]]
[[ string != string ]]

(( integer == integer ))
(( integer != integer ))
(( integer <= integer ))
(( integer >= integer ))
(( integer < integer ))
(( integer > integer ))

[[ $integer -eq $integer ]]
[[ $integer -ne $integer ]]
[[ $integer -lt $integer ]]
[[ $integer -le $integer ]]
[[ $integer -gt $integer ]]
[[ $integer -ge $integer ]]

(( boolean ))
(( ! boolean ))
(( boolean && boolean ))
(( boolean || boolean ))

=== For Loop :

for_each_element() {
	# list_element
	# list_index
	# break_loop
}

for_loop list_name for_each_element

=== Conditions :

1 liner THEN : condition && { ... }
1 liner ELSE : condition || { ... }
Multi line THEN ELSE : if condition then ... else ... fi

=== Sufficient Conditions :

get_errors_snapshot

check_condition sufficient_condition_X || {
    check_condition sufficient_condition_Y && set_errors_snapshot || {
        check_condition sufficient_condition_Z && set_errors_snapshot || return $function_false
    }
}

EOF














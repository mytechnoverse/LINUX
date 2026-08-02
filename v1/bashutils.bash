#!/usr/bin/bash

test -v bashutils_sourced && return

declare str_low_opt='-l'
declare str_up_opt='-u'
declare int_opt='-i'
declare list_opt='-a'
declare ref_opt='-n'
declare global_opt='-g'
declare exported_opt='-x'
declare readonly_opt='-r'

declare $readonly_opt bashutils_version='1.0.0'

declare bashutils_bash_source
declare $int_opt bashutils_line_number
declare bashutils_function_name
declare $int_opt bashutils_return_code
declare bashutils_standard_output_path
declare bashutils_standard_error_path

declare $list_opt bashutils_commands
declare $list_opt bashutils_errors

declare $int_opt $readonly_opt variable_true=1
declare $int_opt $readonly_opt variable_false=0
declare $int_opt $readonly_opt function_true=0
declare $int_opt $readonly_opt function_false=1

declare $int_opt bashutils_local_context=0
declare $int_opt bashutils_parent_context=1
declare $int_opt bashutils_grand_parent_context=2

declare $readonly_opt bashutils_sourced

# log_command command

log_command() {
    parameter_count_minimum 1 "$@"
    append_list_elements bashutils_commands "$*"
}

# log_command_masked command credentials

log_command_masked() {
    parameter_count_minimum 2 "$@"
    declare bashutils_command="$*"
    log_command "${bashutils_command% *} ********"
}

# set_command_context context_value

set_command_context() {
	parameter_count 1 "$@"
	declare bashutils_context_nest_level=$1
    get_list_element BASH_SOURCE $(( 1 + bashutils_context_nest_level )) bashutils_bash_source
    get_list_element FUNCNAME $(( 1 + bashutils_context_nest_level )) bashutils_function_name
    get_list_element BASH_LINENO $(( 0 + bashutils_context_nest_level )) bashutils_line_number
	bashutils_standard_output_path=$(mktemp)
	bashutils_standard_error_path=$(mktemp)
}

# log_error "$@"

log_error() {
	bashutils_return_code=$?
	parameter_count_minimum 1 "$@"
	declare bashutils_command_name=$1
	declare bashutils_error_timestamp="$(date -u +'%Y/%m/%d %H:%M:%S')"
	declare bashutils_command_line="$*"
	declare bashutils_standard_output=$(<"$bashutils_standard_output_path")
	declare bashutils_standard_error=$(<"$bashutils_standard_error_path")
	append_list_elements bashutils_errors_list $(
		cat <<-EOF
		Time Stamp      : $bashutils_error_timestamp
		Script Name     : $bashutils_bash_source
		Line Number     : $bashutils_line_number
		Function Name   : ${bashutils_function_name:-main}
		Command Line    : $bashutils_command_line
		Return Code     : $bashutils_command_name ( $bashutils_return_code )
		Standard Output : $bashutils_standard_output
		Standard Error  : $bashutils_standard_error
		EOF
	)
}


# mask_command command_line command_line_masked

# log error with sensetive

# log_error_message error_message "$@"

log_error_message() {
	bashutils_return_code=$?
	parameter_count_minimum 2 "$@"
	declare bashutils_script_error="$1"
	shift
	declare bashutils_command_name=$1
	declare bashutils_error_timestamp="$(date -u +'%Y/%m/%d %H:%M:%S')"
	declare bashutils_command_line="$*"
	declare bashutils_standard_output=$(<"$bashutils_standard_output_path")
	declare bashutils_standard_error=$(<"$bashutils_standard_error_path")
	append_list_elements bashutils_errors_list $(
		cat <<-EOF
		Time Stamp      : $bashutils_error_timestamp
		Script Name     : $bashutils_bash_source
		Line Number     : $bashutils_line_number
		Function Name   : ${bashutils_function_name:-main}
		Command Line    : $bashutils_command_line
		Return Code     : $bashutils_command_name ( $bashutils_return_code )
		Standard Output : $bashutils_standard_output
		Standard Error  : $bashutils_standard_error
		Script Error    : $bashutils_script_error
		EOF
	)
}

# log_error_sensetive_message

# execute_command command

execute_command() {
    parameter_count_minimum 1 "$@"
    set_command_context $bashutils_grand_parent_context
    "$@" 1>"$standard_output_path" 2>"$standard_error_path" || log_error
	rm -f $bashutils_standard_error_path
	rm -f $bashutils_standard_output_path
    return $bashutils_return_code
}

# execute_command_error error_message command

execute_command_error() {
    parameter_count_minimum 2 "$@"
    declare error_message="$1"
    declare command_name=$2
    declare bash_source 
    declare function_name
    declare $int_opt line_number
    get_command_context 2 bash_source function_name line_number
    declare $int_opt return_code=$function_true
    declare standard_error_path=$(mktemp)
    "$@" 1>/dev/null 2>"$standard_error_path" || {
        return_code=$?
        log_error_message "$error_message"
    }
    rm -f "$standard_error_path"
    return $return_code
}

# run_command command

run_command() {
    parameter_count_minimum 1 "$@"
    log_command "$@"
    declare $int_opt return_code=$function_true
    execute_command "$@" || return_code=$?
    return $return_code
}

# run_command_error error_message command

run_command_error() {
    parameter_count_minimum 2 "$@"
    declare script_error="$1"
    shift
    log_command "$@"
    declare $int_opt return_code=$function_true
    execute_command_error "$script_error" "$@" || return_code=$?
    return $return_code
}

# run_command_sensetive command credentials

run_command_sensetive() {
    parameter_count_minimum 1 "$@"
    log_command_masked "$@"
    declare $int_opt return_code=$function_true
    execute_command "$@" || return_code=$?
    return $return_code
}

# run_command_sensetive_error error_message command credentials

run_command_sensetive_error() {
    parameter_count_minimum 2 "$@"
    declare script_error="$1"
    shift
    log_command_masked "$@"
    declare $int_opt return_code=0
    execute_command_error "$script_error" "$@" || return_code=$?
    return $return_code
}










# declare $int_opt command_result
# test_command command_result command

test_command() {
    parameter_count_minimum 2 "$@"
    declare $ref_opt return_code_ref=$1
    return_code_ref=0
    shift
    declare $list_opt bashutils_notifications_list_before
    copy_list bashutils_notifications_list bashutils_notifications_list_before
    declare $list_opt bashutils_commands_list_before
    copy_list bashutils_commands_list bashutils_commands_list_before
    declare $list_opt bashutils_errors_list_before
    copy_list bashutils_errors_list bashutils_errors_list_before
    declare $list_opt bashutils_functions_list_before
    "$@" &>/dev/null || return_code_ref=$?
    copy_list bashutils_notifications_list_before bashutils_notifications_list
    copy_list bashutils_commands_list_before bashutils_commands_list
    copy_list bashutils_errors_list_before bashutils_errors_list
}

# check_condition condition

check_condition() {
    parameter_count_minimum 1 "$@"
    declare $int_opt command_result
    test_command command_result "$@"
    (( command_result == function_true )) && {
        return $function_true
    } || {
        return $function_false
    }
}

# check_condition_inverted condition

check_condition_inverted() {
    parameter_count_minimum 1 "$@"
    declare $int_opt command_result
    test_command command_result "$@"
    (( command_result == function_true )) && {
        return $function_false
    } || {
        return $function_true
    }
}

# check_condition_notify notification_message condition

check_condition_notify() {
    parameter_count_minimum 2 "$@"
    declare script_notification="$1"
    shift
    declare $int_opt command_result
    test_command command_result "$@"
    (( command_result == function_true )) && {
        append_list_elements bashutils_errors_list "$script_notification"
        return $function_true
    } || {
        return $function_false
    }
}

# check_condition_inverted_notify notification_message condition

check_condition_inverted_notify() {
    parameter_count_minimum 2 "$@"
    declare script_notification="$1"
    shift
    declare $int_opt command_result
    test_command command_result "$@"
    (( command_result == function_true )) && {
        return $function_false
    } || {
        append_list_elements bashutils_errors_list "$script_notification"
        return $function_true
    }
}






# log_error_message error_message

log_error_message() {
    parameter_count 1 "$@"
    declare script_error="$1"
    declare standard_error=$(<"$standard_error_path")
    declare error_entry="[ ${bash_source}:${line_number} ] ${function_name:-main}() : ${command_name} exit code ( ${return_code} )"
    [[ -n "$standard_error" ]] && error_entry+=" | standard error : ( ${standard_error} )"
    error_entry+=" | script error : ( ${script_error} )"
    append_list_elements bashutils_errors_list "$error_entry"
}




# check_condition_error error_message condition

check_condition_error() {
    parameter_count_minimum 2 "$@"
    declare script_error="$1"
    shift
    declare $int_opt command_result
    declare command_name=$1
    declare bash_source 
    declare function_name
    declare $int_opt line_number
    get_command_context 1 bash_source function_name line_number
    test_command command_result "$@"
    (( command_result == function_true )) && {
        return $function_true
    } || {
        append_list_elements bashutils_errors_list "$script_error"
        return $function_false
    }
}

# check_condition_inverted_error error_message condition

check_condition_inverted_error() {
    parameter_count_minimum 2 "$@"
    declare script_error="$1"
    shift
    declare $int_opt command_result
    test_command command_result "$@"
    (( command_result == function_true )) && {
        append_list_elements bashutils_errors_list "$script_error"
        return $function_false
    } || {
        return $function_true
    }
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













# assign_integer








: <<'EOF'

#!/bin/bash
set -Eeuo pipefail

=== Syntax :

[[ string == string ]]
[[ string != string ]]

(( integer == integer ))
(( integer != integer ))
(( integer <= integer ))
(( integer >= integer ))
(( integer < integer ))
(( integer > integer ))

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

EOF





# expect_error() { :; }

# define_list variable_name=()
# assign_list variable_name 'abc' 'xyz'






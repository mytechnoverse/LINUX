#!/usr/bin/bash

test -v bashutils_sourced && return
declare string_opt=''
declare string_lowercase_opt='-l'
declare string_uppercase_opt='-u'
declare boolean_opt='-i'
declare integer_opt='-i'
declare list_opt='-a'
declare reference_opt='-n'
declare global_opt='-g'
declare exported_opt='-x'
declare readonly_opt='-r'
declare "$readonly_opt" bashutils_version='1.0.0'
declare "$list_opt" bashutils_errors_list
declare "$list_opt" bashutils_functions_list
declare "$list_opt" bashutils_sources_list
declare "$list_opt" bashutils_lines_list
declare "$list_opt" bashutils_commands_list
declare "$readonly_opt" bashutils_sourced

declare "$boolean_opt" "$readonly_opt" variable_true=1
declare "$boolean_opt" "$readonly_opt" variable_false=0

declare "$boolean_opt" "$readonly_opt" function_true=0
declare "$boolean_opt" "$readonly_opt" function_false=1

declare "$integer_opt" current_function_index=0
declare "$integer_opt" parent_function_index=1




run_command() {
    append_list_elements bashutils_commands_list "$*"
    "$@"
}

# declare "$boolean_opt" function_name_conditions_verdict
# check_required_condition function_name_conditions_verdict condition

add_required_condition() {
    declare "$reference_opt" verdict_reference="$1"
    shift
    (( verdict_reference == $variable_true )) && {
        "$@" 2>/dev/null || {
            verdict_reference=$variable_false
        }
    }
    return 0
}

# check_sufficient_condition function_name_conditions_verdict condition

add_sufficient_condition() {
    declare "$reference_opt" verdict_reference="$1"
    shift
    (( verdict_reference == $variable_false )) && {
        "$@" 2>/dev/null && {
            verdict_reference=$variable_true
        }
    }
    return 0
}

FINAL WAY :
==================================================================
#!/bin/bash
set -Eeuo pipefail

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







add_true_condition() {
    parameter_count_minimum 2 "$@"
    append_list_elements function_name_conditions 
}

add_false_condition() {
    parameter_count_minimum 2 "$@"

}

# revert false conditions return code and append to same array





# 0 = true , 1 = false
# and between true_conditions

get_logical_and() {

}

get_logical_or() {

}



AND :

for cond in "${conditions[@]}"
do
    (( $1 != function_true ))
done

# or between false_conditions

declare "$list_opt" function_name_false_conditions

OR : 

for cond in "${conditions[@]}"
do
    (( $1 == function_true ))
done
return $function_false























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

get_list_length() {
    parameter_count 2 "$@"
    declare "$reference_opt" list_reference="$1"
    declare "$reference_opt" list_length="$2"
    list_length=${#list_reference[@]}
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






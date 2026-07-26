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

# is_value_integer integer_value ( -1 : true , 0 : true , 1 : true )

is_value_integer() {
    parameter_count 1 "@"
    expect_error "value ( $1 ) is not an integer" [[ "$1" =~ ^-?[0-9]+$ ]]
}

# is_value_integer_whole integer_value ( -1 : false , 0 : true , 1 : true ) 

is_value_integer_whole() {
    parameter_count 1 "@"
    expect_error "value ( $1 ) is not a whole number" [[ "$1" =~ ^[0-9]+$ ]]
}

# is_vlaue_integer_natural integer_value ( -1 : false , 0 : false , 1 : true ) 

is_value_integer_natural() {
    parameter_count 1 "@"
    expect_error "value ( $1 ) is not a natural number" [[ "$1" =~ ^[1-9][0-9]*$ ]]
}

# is_value_boolean boolean_value

is_value_boolean() {
    parameter_count 1 "@"
    expect_error "value ( $1 ) is not a boolean" [[ "$1" =~ ^[01]$ ]]
}

# is_variable_declared variable_name

is_variable_declared() {
    parameter_count 1 "@"
    expect_error "variable ( $1 ) is not declared" [[ -v "$1" ]]
}

# is_value_assigned value 

is_value_assigned() {
    parameter_count 1 "@"
    expect_error "variable ( $1 ) is not assigned" [[ -n "$1" ]]
}

# declare "$list_opt" function_name_conditions

declare "$list_opt" is_string_conditions



# requirement | exception


# add_true_condition function_name_conditions command_name

add_true_condition() {

}

add_false_condition() {}

# add_false_condition function_name_conditions command_name
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
    parameter_count 1 "@"
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


# is_variable_type_string variable_name

is_variable_type_string() {
    parameter_count 1 "@"
    is_variable_defined "$1"
    declare "$string_opt" variable_definition
    variable_definition=$(declare -p "$1" 2>/dev/null)
    [[ "$variable_definition" =~ ^declare[[:space:]]-[^[:space:]]*[aAi] ]]
    false_condition=$?
    expect_error "variable ( $1 ) type is not string" [[ ! $false_condition ]]
}

is_variable_type_integer() {
    parameter_count 1 "@"
    is_variable_defined "$1"
    declare "$string_opt" variable_definition
    variable_definition=$(declare -p "$1" 2>/dev/null)
    [[ "$variable_definition" =~ ^declare[[:space:]]-[^[:space:]]*i ]]
    true_condition=$?
    expect_error "variable ( $1 ) type is not integer" [[ $true_condition ]]
}

is_variable_type_boolean() {
    parameter_count 1 "@"
    is_variable_defined "$1"
    declare "$string_opt" variable_definition
    variable_definition=$(declare -p "$1" 2>/dev/null)
    [[ "$variable_definition" =~ ^declare[[:space:]]-[^[:space:]]*i ]]
    true_condition=$?
    expect_error "variable ( $1 ) type is not boolean" [[ $true_condition ]]
}







# define_integer list_length_variable_name
# get_list_length list_variable_name list_length_variable_name

get_list_length() {
    parameter_count 2 "@"
    define_reference list_reference="$1"
    define_reference list_length="$2"
    list_length="${#list_reference[@]}"
}

# append_list_elements list_name list_element_value ...

append_list_elements() {
    parameter_count_minimum 2 "$@"
    is_variable_type_list "$1"
    declare "$list_opt" list_reference="$1"
    shift
    list_reference+=("$@")
}

# for_each_element() { echo "$1" }
# for_loop list_name for_each_element

for_loop() {
    declare "$reference_opt" list_reference="$1"
    declare "$string_opt" function_name="$2"
    declare "$integer_opt" loop_break=$variable_false
    declare "$integer_opt" list_index
    for list_index in "${!list_reference[@]}"
    do
        "$function_name" "list_reference[$list_index]" "$list_index" loop_break
        (( loop_break == $variable_false )) || {
            break
        }
    done
}

for_each_element() {
    declare "$reference_opt" list_element_value="$1"
    declare "$integer_opt" list_index=$2
    declare "$reference_opt" loop_break="$3"
    # loop_break=$variable_true
}











# assign_integer







# expect_error() { :; }
# is_value_integer_positive() { :; }



# define_list variable_name=()
# assign_list variable_name 'abc' 'xyz'

# (( integer == integer ))
# (( integer != integer ))
# (( integer <= integer ))
# (( integer >= integer ))
# (( integer < integer ))
# (( integer > integer ))

# (( boolean ))
# (( ! boolean ))
# (( boolean && boolean ))
# (( boolean || boolean ))

# [[ string == string ]]
# [[ string != string ]]




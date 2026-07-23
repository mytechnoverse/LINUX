
# define_string variable_name='Abc'
# define_string_readonly variable_name='Abc'
# define_string_lowercase variable_name='abc'
# define_string_uppercase variable_name='ABC'

# define_integer variable_name=5

# define_boolean variable_name=$function_true
# define_boolean variable_name=$variable_true
# define_boolean variable_name=$function_false
# define_boolean variable_name=$variable_false
# define_boolean_readonly variable_name=$variable_true

# define_variable_global variable_name
# define_integer_global variable_name=5
# define_string_global variable_name='Abc'
# define_boolean_global variable_name=$variable_true
# define_boolean_global_exported variable_name=$variable_true

# define_list variable_name=()
# assign_list variable_name 'abc' 'xyz'

# define_reference refrence_name=variable_name 

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

declare -p bashutils_sourced 2>/dev/null || return 1
declare -r bashutils_version='1.0.0'
declare -a bashutils_errors_list
declare -a bashutils_functions_list
declare -a bashutils_sources_list
declare -a bashutils_lines_list
declare -a bashutils_commands_list
declare -r bashutils_sourced














define_aliases() {
    shopt -s expand_aliases
    alias define_variable_global='declare -g'
    alias define_string='declare'
    alias define_string_global='declare -g'
    alias define_string_lowercase='declare -l'
    alias define_string_uppercase='declare -u'
    alias define_string_readonly='declare -r'
    alias define_integer='declare -i'
    alias define_integer_global='declare -ig'
    alias define_boolean='declare -i'
    alias define_boolean_readonly='declare -ir'
    alias define_boolean_global='declare -ig'
    alias define_boolean_global_exported='declare -igx'
    alias define_list='declare -a'
    alias define_reference='declare -n'
    declare -gr bashutils_aliases_defined
}

define_boolean_readonly function_true=0
define_boolean_readonly function_false=1
define_boolean_readonly variable_true=1
define_boolean_readonly variable_false=0

define_integer current_function_index=0
define_integer parent_function_index=1

define_boolean true_condition
define_boolean false_condition


run() { :; }

# parameter_count 1 "$@" || return $function_false

parameter_count() {
    define_integer target_parameter_count="$1"
    define_integer parameter_count="$#"
    parameter_count=$((parameter_count - 1))
    true_condition=$(( target_parameter_count == parameter_count ))
    define_string parent_function_name="${FUNCNAME[$parent_function_index]}"
    (( true_condition )) || {
        add_error_trace "${parent_function_name} function requires ${target_parameter_count} parameter(s)"
    }
}

# is_variable_defined "$1" || return $function_false

is_variable_defined() {
    require_parameter 1 "$@" || return $function_false
    define_string variable_name="$1"
    true_condition=[[ declare -p $variable_name &>/dev/null ]]
    (( true_condition )) || {
        return 1
    }
}


get_list_length() {
    define_reference list_reference="$1"
    define_reference list_length="$2"
    list_length="${#list_reference[@]}"
}

remove_list_index() {
    define_string list_name="$1"
    define_integer list_index="$2"
    get_list_length $list_name list_length
    true_condition=$(( $((list_index + 1)) <= $list_length))
    (( true_condition )) || {
        return $function_false
    }
    unset 'list_name[-1]'
    list_name=("${list_name[@]}")
}

append_list() {
    define_reference list_reference="$1"
    shift
    list_reference+=("$@")
}

add_error_trace() {
    append_list bashutils_errors_list "$1"
    append_list bashutils_functions_list "${FUNCNAME[1]:-main}"
    append_list bashutils_sources_list "${BASH_SOURCE[1]:-script}"
    append_list bashutils_lines_list "${BASH_LINENO[0]:-0}"
}

try() {
    define_string bashutils_error_message="$1"
    shift
    trace_error "$bashutils_error_message"
    "$@" || return $function_false
    define_integer bashutils_errors_count
    get_list_length bashutils_errors_list bashutils_errors_count 
    (( $bashutils_error_count < 0 )) || {
        unset 'bashutils_errors_list[-1]'
        unset 'bashutils_functions_list[-1]'
        unset 'bashutils_sources_list[-1]'
        unset 'bashutils_lines_list[-1]'
        bashutils_errors_list=()
    }
}


try_pop() {
  if (( ${#ERROR_STACK[@]} > 0 ))
  then
    unset 'ERROR_STACK[-1]'
    unset 'ERROR_STACK_FUNCS[-1]'
    unset 'ERROR_STACK_FILES[-1]'
    unset 'ERROR_STACK_LINES[-1]'
    ERROR_STACK=("${ERROR_STACK[@]}")
    ERROR_STACK_FUNCS=("${ERROR_STACK_FUNCS[@]}")
    ERROR_STACK_FILES=("${ERROR_STACK_FILES[@]}")
    ERROR_STACK_LINES=("${ERROR_STACK_LINES[@]}")
  fi
}

try() {
  local error_msg="$1"
  shift
  try_push "$error_msg"
  if "$@"
  then
    try_pop
  else
    return 1
  fi
}












undefine_aliases() {
    (( ! bashutils_aliases_defined )) || {
        unalias define_integer 2>/dev/null
        bashutils_aliases_defined=variable_false
    }
}



trap bashutils_exit_handler EXIT





















# remove_list_index list_variable_name list_index

remove_list_index() {
    expect_error "list variable name ( ${list_name} ) not defined" is_variable_defined "$1"
    define_string list_name="$1"
    expect_error "list index " is_value_integer "$2"
    define_integer list_index="$2"
    define_integer list_length
    get_list_length "$list_name" list_length
    true_condition=$((list_index < list_length))
    expect_error "list ( ${list_name} ) : list index ( ${list_index} ) bigger than list length ( ${list_length} )" (( true_condition ))
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










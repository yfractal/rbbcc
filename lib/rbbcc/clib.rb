require 'fiddle/import'

module RbBCC
  module Clib
    extend Fiddle::Importer
    dlload "libbcc.so.0"

    extern 'void * bpf_module_create_c_from_string(char *, unsigned int, char **, int, long)'
    extern 'int bpf_num_functions(void *)'
    extern 'char * bpf_function_name(void *, int)'

    extern 'int bcc_func_load(void *, int, char *, void *, int, char *, unsigned int, int, char *, unsigned int)'
    extern 'void * bpf_function_start(void *, char *)'
    extern 'int bpf_function_size(void *, char *)'
    extern 'char * bpf_module_license(void *)'
    extern 'unsigned int bpf_module_kern_version(void *)'

    extern 'int bpf_attach_kprobe(int, int, char *, char *, unsigned int, int)'
  end
end

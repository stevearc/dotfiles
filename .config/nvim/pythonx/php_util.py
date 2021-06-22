def extract_type_args(arglist):
    return [arg.strip() for arg in arglist.split(',') if arg.strip()]

def extract_types_from_args(arglist):
    return [pair.split()[0] for pair in extract_type_args(arglist)]

def get_args(arglist, injected=False):
    args = [arg.strip() for arg in arglist.split(',') if arg]
    if injected:
        args = [arg for arg in args if arg.startswith('$')]
    return args

def format_deps(arglist):
    args = get_args(arglist, injected=True)
    line = ''
    for arg in args:
        line += "'%s', " % arg
    return line

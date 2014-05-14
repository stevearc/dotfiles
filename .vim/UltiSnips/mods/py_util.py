def get_args(arglist):
    args = [arg.split('=')[0].strip() for arg in arglist.split(',') if arg]
    args = [arg for arg in args if arg and arg != "self"]

    return args


def write_init_body(classname, args, parents, snip):
    if parents != 'object':
        snip += 'super(%s, self).__init__()' % classname

    for arg in args:
        snip += "self._%s = %s" % (arg, arg)

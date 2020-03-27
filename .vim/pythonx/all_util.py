""" Ultisnips utilities for all filetypes """


def snake_to_camel_case(word):
    """ Convert snake case to camel case """
    return ''.join(x.capitalize() or '_' for x in word.split('_'))

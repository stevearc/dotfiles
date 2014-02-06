def gen_column_class(text):
    """
    Generate column classes for a spec

    xs8 -> col-xs-8
    xs8 md3,6 -> col-xs-8 col-md-offset-3 col-md-6

    """
    classes = []
    for spec in text.split():
        screen, placement = spec[:2], spec[2:]
        if ',' in placement:
            offset, size = placement.split(',')
            classes.append('col-%s-offset-%s' % (screen, offset))
        else:
            size = placement
        classes.append('col-%s-%s' % (screen, size))
    return ' '.join(classes)

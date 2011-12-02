require 'mkmf'

$CFLAGS += " -std=c99"
$warnflags = ''
CONFIG['warnflags'] = ''

create_makefile('gravsim_native/gravsim_native')

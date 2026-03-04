# frozen_string_literal: true

require 'mkmf'

append_cflags(%w[-Wall -Wextra -Wno-unused-parameter])

create_makefile('macaw_framework_ext')

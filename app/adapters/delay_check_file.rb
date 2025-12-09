# frozen_string_literal: true
# DelayCheckFile tries to see if the file times out before it opens the IO, in
# case TigerData is frozen.
class DelayCheckFile
  delegate(*(File.instance_methods - Object.instance_methods), to: :_inner_file)

  def initialize(wrapped_io, file_path)
    @wrapped_io = wrapped_io
    @file_path = file_path
  end

  def _inner_file
    @_inner_file ||=
      begin
        # The first time the IO is accessed as a file it'll attempt to check the
        # size of the file, if it times out because Tigerdata's dead it'll raise
        # an error and crash immedaitely. This should take a fraction of a
        # fraction of a second.
        Timeout.timeout(1) do
          File.size(@file_path)
        end
        @wrapped_io
      end
  end
end

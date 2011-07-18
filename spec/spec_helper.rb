require 'rspec'

require 'eyeliner'

require 'pathname'

$project_dir = Pathname(__FILE__).expand_path.parent.parent
$tmp_dir = $project_dir + "tmp"

RSpec.configure do |config|

  config.before(:each) do
    if $tmp_dir.exist?
      $tmp_dir.rmtree
    end
  end

end

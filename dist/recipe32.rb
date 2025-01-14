require_relative 'tools'

class GraylogSidecar < FPM::Cookery::Recipe
  description 'Graylog sidecar'

  name     'graylog-sidecar'
  version  data.version
  revision data.revision
  homepage 'https://graylog.org'
  arch     'i386'

  source   "file:../../build/#{version}/linux/386/graylog-sidecar"

  maintainer 'Graylog, Inc. <hello@graylog.org>'
  vendor     'graylog'
  license    'SSPL'

  config_files '/etc/graylog/sidecar/sidecar.yml'

  fpm_attributes rpm_os: 'linux'

  def build
  end

  def install
    bin.install 'graylog-sidecar'
    lib('graylog-sidecar').install '../../collectors/filebeat/linux/x86/filebeat'
    lib('graylog-sidecar').install '../../collectors/auditbeat/linux/x86/auditbeat'
    etc('graylog/sidecar').install '../../../sidecar-example.yml', 'sidecar.yml'
    var('lib/graylog-sidecar/generated').mkdir
    var('log/graylog-sidecar').mkdir
    var('run/graylog-sidecar').mkdir
  end
end

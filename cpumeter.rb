cask :v1 => 'cpumeter' do
  version '1.0.3'
  sha256 '078936bffa150083217f0f171522c0dfafb42b3a03e6c7ebd8295bb57753cc2a'

  url 'https://github.com/fataio/cpumeter/blob/master/dist/cpumeter.pkg?raw=true'
  name 'cpumeter'
  homepage 'https://github.com/fataio/cpumeter/'
  license :oss

  pkg 'cpumeter.pkg'

  uninstall :pkgutil => 'io.fata.app.cpumeter'
end

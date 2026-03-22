class Jumper < Formula
  desc "CLI tool for quickly navigating between directories by name"
  homepage "https://github.com/yixun/jumper"
  url "https://github.com/yixun/jumper/archive/v0.1.1.tar.gz"
  sha256 :no_check  # Replace with actual SHA256 when releasing
  license "MIT"
  head "https://github.com/yixun/jumper.git", branch: "main"

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args
  end

  def caveats
    <<~EOS
      To use Jumper, add the following to your shell configuration (~/.zshrc, ~/.bashrc, etc.):

        export JUMPER_HOME=#{HOMEBREW_PREFIX}/var/jumper
        export JUMPER_WORKSPACE=$HOME
        export JUMPER_DEPTH=4
        source #{HOMEBREW_PREFIX}/var/jumper/jumperrc

      Then create the configuration file:

        mkdir -p #{HOMEBREW_PREFIX}/var/jumper
        cat > #{HOMEBREW_PREFIX}/var/jumper/jumperrc << 'EOF'
        export JUMPER_HOME=#{HOMEBREW_PREFIX}/var/jumper
        export JUMPER_WORKSPACE=$HOME
        export JUMPER_DEPTH=4
        alias j='. #{HOMEBREW_PREFIX}/var/jumper/jumper.sh'
        alias jadd='#{bin}/jumper add'
        alias jassemble='#{bin}/jumper assemble'
        alias jalias='#{bin}/jumper alias'
        alias jlist='#{bin}/jumper list'
        alias jremove='#{bin}/jumper remove'
        EOF

      Finally, reload your shell:

        exec "$SHELL" -l
    EOS
  end

  test do
    output = shell_output("#{bin}/jumper --version")
    assert_match "jumper", output
  end
end

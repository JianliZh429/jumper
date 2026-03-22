class Jumper < Formula
  desc "CLI tool for quickly navigating between directories by name"
  homepage "https://github.com/JianliZh429/jumper"
  url "https://github.com/JianliZh429/jumper/archive/refs/tags/v0.1.1.tar.gz"
  # sha256: Add actual SHA256 checksum when releasing
  # To get SHA256: curl -LO <url> && shasum -a 256 <file>
  license "MIT"
  head "https://github.com/JianliZh429/jumper.git", branch: "main"

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args
    
    # Install shell integration scripts
    (share/"jumper").install "jumper.sh"
    (share/"jumper").install "install.sh"
  end

  def post_install
    # Set up Jumper home directory
    jumper_home = ENV["JUMPER_HOME"] || "#{ENV["HOME"]}/.jumper"
    mkdir_p jumper_home

    # Copy shell script to jumper home
    if File.exist?(share/"jumper/jumper.sh")
      cp share/"jumper/jumper.sh", "#{jumper_home}/jumper.sh"
      chmod 0755, "#{jumper_home}/jumper.sh"
    end

    # Create configuration file
    jumperrc = "#{jumper_home}/jumperrc"
    workspace = ENV["JUMPER_WORKSPACE"] || ENV["HOME"]
    depth = ENV["JUMPER_DEPTH"] || "4"

    File.write(jumperrc, <<~EOS)
      export JUMPER_HOME=#{jumper_home}
      export JUMPER_WORKSPACE=#{workspace}
      export JUMPER_DEPTH=#{depth}
      alias j='. #{jumper_home}/jumper.sh'
      alias jadd='#{bin}/jumper add'
      alias jassemble='#{bin}/jumper assemble'
      alias jalias='#{bin}/jumper alias'
      alias jlist='#{bin}/jumper list'
      alias jremove='#{bin}/jumper remove'
    EOS

    chmod 0644, jumperrc
  end

  def caveats
    <<~EOS
      Jumper has been installed! To start using it, add the following to your
      shell configuration file (~/.zshrc, ~/.bashrc, or ~/.bash_profile):

        source #{ENV["HOME"]}/.jumper/jumperrc

      Then reload your shell:

        exec "$SHELL" -l

      Quick start:

        j              # Jump to workspace root
        j <name>       # Jump to a registered directory
        jadd <name> <path>  # Register a new directory
        jlist          # List all registered directories

      For more information, see: https://github.com/JianliZh429/jumper
    EOS
  end

  test do
    output = shell_output("#{bin}/jumper --version")
    assert_match "jumper", output
  end
end

{ lib, buildGoModule, fetchFromGitHub, installShellFiles }:

buildGoModule rec {
  pname = "chezmoi";
  version = "2.22.0";

  src = fetchFromGitHub {
    owner = "twpayne";
    repo = "chezmoi";
    rev = "v${version}";
    sha256 = "sha256-igZURbPa4ldhkjae6olAbW9L8qddxZj6wwkIJ3L23aA=";
  };

  vendorSha256 = "sha256-riGN7d+am9DXCcFVkc2WIxmHvsNaZxHm/aEDcb8kCz4=";

  doCheck = false;

  ldflags = [
    "-s" "-w" "-X main.version=${version}" "-X main.builtBy=nixpkgs"
  ];

  nativeBuildInputs = [ installShellFiles ];

  postInstall = ''
    installShellCompletion --bash --name chezmoi.bash completions/chezmoi-completion.bash
    installShellCompletion --fish completions/chezmoi.fish
    installShellCompletion --zsh completions/chezmoi.zsh
  '';

  subPackages = [ "." ];

  meta = with lib; {
    homepage = "https://www.chezmoi.io/";
    description = "Manage your dotfiles across multiple machines, securely";
    license = licenses.mit;
    maintainers = with maintainers; [ jhillyerd ];
  };
}

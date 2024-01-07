{ pkgs }:
rec {
  /* Prepare a derivation for local builds.
    *
    * This function prepares checkpoint builds by provinding,
    * containing the build output and the sources for cross checking.
    * The build output can be used later to allow checkpoint builds
    * by passing the derivation output to the `mkCheckpointBuild` function.
    *
    * To build a project with checkpoints follow these steps:
    * - run prepareIncrementalBuild on the desired derivation
    *   e.G `incrementalBuildArtifacts = (pkgs.checkpointBuildTools.prepareCheckpointBuild pkgs.virtualbox);`
    * - change something you want in the sources of the package( e.G using source override)
    *   changedVBox = pkgs.virtuabox.overrideAttrs (old: {
    *      src = path/to/vbox/sources;
    *   }
    * - use `mkCheckpointBuild changedVBox incrementalBuildArtifacts`
    * - enjoy shorter build times
  */
  prepareCheckpointBuild = drv: drv.overrideAttrs (old: {
    outputs = [ "out" ];
    name = drv.name + "-checkpointArtifacts";
    # To determine differences between the state of the build directory
    # from an earlier build and  a later one we store the state of the build
    # directory before build, but after patch phases.
    # This way, the same derivation can be used multiple times and only changes are detected.
    # Additionally Removed files are handled correctly in later builds.
    preBuild = (old.preBuild or "") + ''
      mkdir -p $out/sources
      cp -r ./* $out/sources/
    '';

    # After the build the build directory is copied again
    # to get the output files.
    # We copy the complete build folder, to take care for
    # Build tools, building in the source directory, instead of
    # having a build root directory, e.G the Linux kernel.
    installPhase = ''
      runHook preCheckpointInstall
      mkdir -p $out/outputs
      cp -r ./* $out/outputs/
      runHook postCheckpointInstall
    '';
  });

  /* Build a derivation based on the checkpoint output generated by
    * the `prepareCheckpointBuild function.
    *
    * Usage:
    * let
    *   checkpointArtifacts = prepareCheckpointBuild drv
    * in mkCheckpointBuild drv checkpointArtifacts
  */
  mkCheckpointBuild = drv: previousBuildArtifacts: drv.overrideAttrs (old: {
    # The actual checkpoint build phase.
    # We compare the changed sources from a previous build with the current and create a patch
    # Afterwards we clean the build directory to copy the previous output files (Including the sources)
    # The source difference patch is applied to get the latest changes again to allow short build times.
    preBuild = (old.preBuild or "") + ''
      set +e
      diff -ur ${previousBuildArtifacts}/sources ./ > sourceDifference.patch
      set -e
      shopt -s extglob dotglob
      rm -r !("sourceDifference.patch")
      ${pkgs.rsync}/bin/rsync -cutU --chown=$USER:$USER --chmod=+w -r ${previousBuildArtifacts}/outputs/* .
      patch -p 1 -i sourceDifference.patch
    '';
  });

  mkCheckpointedBuild = pkgs.lib.warn
    "`mkCheckpointedBuild` is deprecated, use `mkCheckpointBuild` instead!"
    mkCheckpointBuild;
}

export PROMPT_START=">"
export PROMPT_END="<"
export GHC="/home/ares/ghc.worktrees/wip/T25903_new/_build/stage1/bin/ghc"
# # export GHC=/home/ares/bin/ghc
export HC=$GHC
# # export GHC=/home/ares/.ghcup/bin/ghc
# # export HC=/home/ares/.ghcup/bin/ghc
#  . .gitlab/ci.sh setup
# export CONFIGURE_ARGS="--enable-bootstrap-with-devel-snapshot"
#  . .gitlab/ci.sh configure
export CORES="$(mk/detect-cpu-count.sh)"
# export CABFLAGS="--allow-newer"
HADRIAN_ARGS=-j$CORES hadrian/ghci-multi -j$CORES
# HADRIAN_ARGS=-j$CORES hadrian/build --flavour=quickest -j$CORES


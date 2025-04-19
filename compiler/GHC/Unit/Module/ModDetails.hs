module GHC.Unit.Module.ModDetails
   ( ModDetails (..)
   , emptyModDetails
   , get_md_types
   , get_md_defaults
   )
where

import GHC.Core         ( CoreRule )
import GHC.Core.FamInstEnv
import GHC.Core.InstEnv ( InstEnv, emptyInstEnv )

import GHC.Types.Avail
import GHC.Types.CompleteMatch
import GHC.Types.DefaultEnv
import GHC.Types.TypeEnv
import GHC.Types.Annotations ( Annotation )
import GHC.Stack (HasCallStack)
import System.IO (IO)
import Data.Either (Either(..))
import Control.Exception (SomeException, try)
import GHC.Utils.Panic (pprPanic)
import GHC.Utils.Outputable (text, IsLine ((<+>)))
import GHC.Prelude (Show(..), Monad (return))

get_md_types :: HasCallStack => ModDetails -> IO TypeEnv
get_md_types md = tryAndPanic (return (md_types md))

get_md_defaults :: HasCallStack => ModDetails -> IO DefaultEnv
get_md_defaults md = tryAndPanic (return (md_defaults md))

tryAndPanic :: forall a. IO a -> IO a
tryAndPanic action = do
  result <- try action :: IO (Either SomeException a)
  case result of
    Left ex  -> pprPanic "tryAndPanic" (text "Exception: " <+> text (show ex))
    Right res  -> return res

-- | The 'ModDetails' is essentially a cache for information in the 'ModIface'
-- for home modules only. Information relating to packages will be loaded into
-- global environments in 'ExternalPackageState'.
data ModDetails = ModDetails
   { -- The next two fields are created by the typechecker
     md_exports   :: [AvailInfo]
   , md_types     :: !TypeEnv
      -- ^ Local type environment for this particular module
      -- Includes Ids, TyCons, PatSyns

   , md_defaults  :: !DefaultEnv
      -- ^ default declarations exported by this module

   , md_insts     :: InstEnv
      -- ^ 'DFunId's for the instances in this module

   , md_fam_insts :: ![FamInst]
   , md_rules     :: ![CoreRule]
      -- ^ Domain may include 'Id's from other modules

   , md_anns      :: ![Annotation]
      -- ^ Annotations present in this module: currently
      -- they only annotate things also declared in this module

   , md_complete_matches :: CompleteMatches
      -- ^ Complete match pragmas for this module
   }

-- | Constructs an empty ModDetails
emptyModDetails :: ModDetails
emptyModDetails = ModDetails
   { md_types            = emptyTypeEnv
   , md_exports          = []
   , md_defaults         = emptyDefaultEnv
   , md_insts            = emptyInstEnv
   , md_rules            = []
   , md_fam_insts        = []
   , md_anns             = []
   , md_complete_matches = []
   }

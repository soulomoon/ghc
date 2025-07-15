{-# LANGUAGE TypeFamilies #-}

module B where


import {-# SOURCE #-} C
import Other
type instance OtherF a b = b

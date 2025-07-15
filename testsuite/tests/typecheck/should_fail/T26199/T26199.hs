{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE UnliftedNewtypes #-}

module Main where

import A
import B
import Other

go :: OtherF String Int
go = 1


main = print go

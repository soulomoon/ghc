{-# LANGUAGE TypeFamilies #-}

module Other where

type family OtherF a b

type family Common a

type instance Common a = a

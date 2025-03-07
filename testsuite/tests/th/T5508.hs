{-# LANGUAGE TemplateHaskell #-}

module T5508 where

import Language.Haskell.TH

thb = $(do { let x = mkName "x"
                 p = VarP x
                 v = return (LamE [VisAP p] $ VarE x)
           ; [| $v . id |] })

module Test.Main where

import Prelude
import Test.Unit (test)
import Test.Main (runTest)
import Control.Monad.Eff (Eff)
import Control.Monad.Eff.Console (CONSOLE, log)

main = runTest do
  test 

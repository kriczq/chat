module Model where

import Prelude

import Control.Alt ((<|>))
import Control.Bind ((=<<))
import Control.Monad.Aff (Aff(), launchAff, runAff)
import Control.Monad.Aff.AVar (AVar(), AVAR(), makeVar, putVar, takeVar)
import Control.Monad.Eff (Eff())
import Control.Monad.Eff.Class (liftEff)
import Control.Monad.Eff.Console (CONSOLE(), log)

import Data.Array (replicate,snoc)
import Data.Function (Fn1(),runFn1)
import Data.Maybe (Maybe(..), isJust, isNothing)
import Data.String (joinWith)

import DOM (DOM())

import Halogen

import WebSocket

-- | The state of the component.
type State = { messages :: Array ChatMessage
             , buffer :: String
             , user :: User
             , socket :: Maybe Connection
             , chatServerUrl :: String
             , queryChan :: AVar (Query Unit)
             }

type ChatMessage = { content :: String}


type User = String


type AppEffects eff = HalogenEffects ( console :: CONSOLE
                                     , ws :: WEBSOCKET
                                     | eff
                                     )


data Query a
  = RecMsg String a
  | SendMsg String a
  | SetBuf String a
  | SetUrl String a
  | SetUserName String a
  | ConnectButton a
  | Connect Connection a
  | Disconnect a


type AppDriver = Query Unit -> Aff (AppEffects ()) Unit

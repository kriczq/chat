module Model (Client, ServerState) where

import Data.Text (Text)
import qualified Network.WebSockets as WS

type Client = (Text, WS.Connection)
type ServerState = [Client]

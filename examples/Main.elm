module Main exposing (main)

import Camellia
import RouteExample


main : Camellia.HttpServer () RouteExample.AppModel RouteExample.Error
main =
    Camellia.createServer RouteExample.app

module Main exposing (main)

import RouteExample
import Camellia


main : Camellia.HttpServer () RouteExample.AppModel RouteExample.Error
main =
    Camellia.createServer RouteExample.exampleApp

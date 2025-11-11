module RouteExample exposing (..)

import Camellia
import Camellia.ErrorHelpers
import Camellia.Http as Camellia
import Camellia.RouteParser as RouteParser
import Camellia.Types as Camellia
import Http
import Json.Decode as Decode
import Json.Encode as Encode
import Task
import TaskPort


exampleApp : Camellia.Application () AppModel Error
exampleApp =
    { routes = [ getUserRoute, getPostRoute, createUserRoute ]
    , notFoundHandler =
        \request ->
            { id = request.id
            , status = 404
            , body = "{\"error\": \"Not Found\"}"
            , headers = []
            }
    , errorHandler = handleError
    , init = \_ -> {}
    }


type alias AppModel =
    {}


type Error
    = TaskPort TaskPort.Error
    | Http Http.Error
    | ValidationError String



-- Example types for a user API


type alias GetUserResponse =
    { id : Int
    , firstName : String
    , lastName : String
    , email : String
    }


type alias CreateUserRequest =
    { firstName : String
    , lastName : String
    , email : String
    }



-- JSON encoders/decoders


encodeUser : GetUserResponse -> Encode.Value
encodeUser user =
    Encode.object
        [ ( "id", Encode.int user.id )
        , ( "firstName", Encode.string user.firstName )
        , ( "lastName", Encode.string user.lastName )
        , ( "email", Encode.string user.email )
        ]


decodeCreateUser : Decode.Decoder CreateUserRequest
decodeCreateUser =
    Decode.map3 CreateUserRequest
        (Decode.field "firstName" Decode.string)
        (Decode.field "lastName" Decode.string)
        (Decode.field "email" Decode.string)


getUserHandler : AppModel -> Camellia.Request { id : Int } () -> Task.Task Error (Camellia.Response GetUserResponse)
getUserHandler _ request =
    let
        userId =
            request.params.id
    in
    if userId <= 0 then
        Task.fail (ValidationError "User ID must be positive")

    else
        let
            user =
                { id = userId
                , firstName = "John"
                , lastName = "Doe"
                , email = "john.doe@example.com"
                }
        in
        Task.succeed
            { id = request.id
            , status = 200
            , body = user
            , headers = [ Camellia.ResponseContentType Camellia.ApplicationJson ]
            }


getPostHandler : AppModel -> Camellia.Request { userId : Int, postId : Int } () -> Task.Task Error (Camellia.Response String)
getPostHandler _ request =
    let
        userId =
            request.params.userId

        postId =
            request.params.postId
    in
    if userId <= 0 || postId <= 0 then
        Task.fail (ValidationError "User ID and Post ID must be positive")

    else
        let
            userIdStr =
                String.fromInt userId

            postIdStr =
                String.fromInt postId
        in
        Task.succeed
            { id = request.id
            , status = 200
            , body = "User " ++ userIdStr ++ " - Post " ++ postIdStr
            , headers = [ Camellia.ResponseContentType Camellia.TextPlain ]
            }


createUserHandler : AppModel -> Camellia.Request () CreateUserRequest -> Task.Task Error (Camellia.Response ())
createUserHandler _ request =
    let
        userData =
            request.body
    in
    if String.isEmpty userData.email then
        Task.fail (ValidationError "Email is required")

    else if String.isEmpty userData.firstName then
        Task.fail (ValidationError "First name is required")

    else if String.isEmpty userData.lastName then
        Task.fail (ValidationError "Last name is required")

    else
        Task.succeed
            { id = request.id
            , status = 201
            , body = ()
            , headers = []
            }


getUserRoute : Camellia.RouteHandler AppModel Error
getUserRoute =
    Camellia.createRoute
        { method = Camellia.GET
        , route =
            RouteParser.defineRoute
                "/user/:id"
                (RouteParser.succeed (\id -> { id = id }) |> RouteParser.required "id" RouteParser.int)
        , requestDecoder = Camellia.emptyRequestBody
        , responseEncoder = Camellia.jsonResponseBody encodeUser
        , handler = getUserHandler
        }


getPostRoute : Camellia.RouteHandler AppModel Error
getPostRoute =
    Camellia.createRoute
        { method = Camellia.GET
        , route =
            RouteParser.defineRoute "/user/:userId/post/:postId"
                (RouteParser.succeed (\userId postId -> { userId = userId, postId = postId })
                    |> RouteParser.required "userId" RouteParser.int
                    |> RouteParser.required "postId" RouteParser.int
                )
        , requestDecoder = Camellia.emptyRequestBody
        , responseEncoder = identity
        , handler = getPostHandler
        }


createUserRoute : Camellia.RouteHandler AppModel Error
createUserRoute =
    Camellia.createRoute
        { method = Camellia.POST
        , route =
            RouteParser.defineRoute "/user" RouteParser.noParams
        , requestDecoder = Camellia.jsonRequestBody decodeCreateUser
        , responseEncoder = Camellia.emptyResponseBody
        , handler = createUserHandler
        }


handleError : Camellia.RequestId -> Error -> Camellia.Response String
handleError requestId error =
    case error of
        TaskPort taskPortError ->
            Camellia.ErrorHelpers.taskPortErrorToResponse requestId taskPortError

        Http httpError ->
            Camellia.ErrorHelpers.httpErrorToResponse requestId httpError

        ValidationError message ->
            { id = requestId
            , status = 422
            , body = "{\"error\": \"Validation Failed\", \"message\": \"" ++ message ++ "\"}"
            , headers = []
            }

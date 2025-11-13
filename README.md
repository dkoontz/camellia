# Camellia

A type-safe HTTP server framework for Node.js, powered by Elm.

## Project Overview

Camellia enables you to build robust, type-safe web servers by writing your business logic in Elm while running on Node.js. The framework bridges the gap between Elm's functional programming paradigm and Node.js's runtime environment.

### Goals

- **Type Safety**: Leverage Elm's type system to eliminate runtime errors in your HTTP handlers
- **Functional Architecture**: Write clean, predictable server code using functional programming principles
- **Node.js Performance**: Deploy to the mature Node.js ecosystem while maintaining type safety
- **Developer Experience**: Catch errors at compile time rather than in production

### Why Camellia Exists

Elm is a functional programming language that compiles to JavaScript and was designed primarily for browser applications. While Elm provides strong type safety and a reliable architecture for frontend development, it doesn't have direct access to Node.js APIs for file system operations, database connections, or other server-side concerns.

Camellia bridges this gap by implementing a providing a framework that lets you write HTTP server logic in Elm while running on Node.js (internally using Platform.worker). You get the benefits of Elm's type system and functional programming model for your server-side business logic, while gaining the ability to deploy on the Node.js runtime environment. Camellia uses the TaskPorts library to enable the addition of custom commands allowing you to access any specific capabilities you need from your platform.

## How to Use It

Eventually there will be a NPM package, for now just clone this repo and update the example code at `examples` with your own application. You can also move the contents of `examples` into `src`.

### Basic Server Setup

1. **Define your application model and routes** in Elm:

```elm
import Camellia
import Camellia.Types as Camellia
import Camellia.Http as Http
import Task

type alias AppModel = 
    { users : List User }


type Error
    = TaskPort TaskPort.Error
    | Http Http.Error
    | ValidationError String


getUserRoute : Camellia.RouteHandler AppModel Error
getUserRoute =
    Camellia.createRoute
        { method = Http.GET
        , route = RouteParser.defineRoute "/users/:id" (RouteParser.required "id" RouteParser.int)
        , requestDecoder = Camellia.emptyRequestBody
        , responseEncoder = Camellia.jsonResponseBody encodeUser
        , handler = getUserHandler
        }


getUserHandler : AppModel -> Camellia.Request { id : Int } () -> Task.Task Error (Camellia.Response User)
getUserHandler model request =
    -- Your business logic here
    case findUserById request.params.id model.users of
        Just user ->
            Task.succeed
                { id = request.id
                , status = 200
                , body = user
                , headers = [ Http.ResponseContentType Http.ApplicationJson ]
                }
        Nothing ->
            Task.fail NotFound
```

2. **Create your main application**:

```elm
-- In Main.elm
import Camellia

main : Camellia.HttpServer () AppModel Error
main =
    Camellia.createServer
        { routes = [ getUserRoute, createUserRoute ]
        , notFoundHandler = \request ->
            { id = request.id
            , status = 404
            , body = "{\"error\": \"Not Found\"}"
            , headers = []
            }
        , errorHandler = handleError
        , init = \_ -> initialModel
        }
```

3. **Build and run**:

```bash
# Development with hot reload
npm run dev

# Production build and start
npm run start

# Build only
npm run build
```

### Environment Configuration

Set environment variables:

- `CAMELLIA_PORT` - Server port (defaults to 3000)
- `NODE_ENV` - Environment setting
- `LOG_LEVEL` - Logging level (info, debug, etc.)

### Route Handling

Camellia supports all HTTP methods and provides type-safe route parameters:

```elm
-- Route with multiple parameters
getPostRoute : Camellia.RouteHandler AppModel Error
getPostRoute =
    Camellia.createRoute
        { method = Http.GET
        , route = RouteParser.defineRoute "/users/:userId/posts/:postId" 
            (RouteParser.required "userId" RouteParser.int
                |> RouteParser.required "postId" RouteParser.int
            )
        , requestDecoder = Camellia.emptyRequestBody
        , responseEncoder = Camellia.stringResponseBody
        , handler = getPostHandler
        }
```

### Request/Response Handling

Use the provided decoders and encoders:

```elm
-- JSON request body
createUserRoute =
    Camellia.createRoute
        { method = Http.POST
        , route = RouteParser.defineRoute "/users" RouteParser.noParams
        , requestDecoder = Camellia.jsonRequestBody decodeCreateUser
        , responseEncoder = Camellia.emptyResponseBody
        , handler = createUserHandler
        }

-- Available body handlers:
-- Camellia.emptyRequestBody / Camellia.emptyResponseBody
-- Camellia.jsonRequestBody decoder / Camellia.jsonResponseBody encoder
-- Camellia.stringResponseBody
```

## Development Workflow

### Code Quality Commands

```bash
# Format code
npm run format

# Validate formatting
npm run format:validate

# Run linter
npm run lint

# Fix linting issues
npm run lint:fix

# Full validation pipeline
npm run validate
```

### Development vs Production

```bash
# Development with debug logging
npm run start:debug

# Development with hot reload
npm run dev

# Production optimized build
npm run build && npm run start
```

## Gotchas and Notes

### Port Communication

- Camellia uses Elm ports to communicate between the Node.js server and Elm application
- All HTTP requests are serialized as JSON and passed through ports
- Responses must be serialized back to JSON for Node.js to handle

### Error Handling

- Define your application's error types in Elm
- Use `Camellia.ErrorHelpers` for common HTTP and TaskPort error conversions
- All errors should result in valid HTTP responses with appropriate status codes

### Type Safety Considerations

- Route parameters are parsed and validated at runtime
- Request body decoding can fail - handle decode errors appropriately
- Response encoders must produce valid strings for the HTTP response body

### Debugging

- Use `LOG_LEVEL=debug` for detailed request/response logging
- Elm's `Debug.log` is available in development builds (`npm run build:debug`)

### Hot Reload

- `npm run dev` provides hot reload during development
- Changes to Elm files trigger automatic recompilation
- The server automatically restarts when changes are detected

### Deployment

- Build production artifacts with `npm run build`
- The compiled output is a single JavaScript file for Node.js
- Set appropriate environment variables for production deployment

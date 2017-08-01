module Request.Search exposing (get)

import Data.Search as Search exposing (SearchResult)
import Http
import HttpBuilder exposing (RequestBuilder, withExpect, withQueryParams)
import Json.Decode as Decode
import Util exposing (apiHost)


get : String -> Http.Request (List SearchResult)
get query =
    let
        url =
            apiHost ++ "/search/" ++ query

        decoder =
            Decode.list Search.decoder
    in
    HttpBuilder.get url
        |> HttpBuilder.withExpect (Http.expectJson decoder)
        |> HttpBuilder.toRequest

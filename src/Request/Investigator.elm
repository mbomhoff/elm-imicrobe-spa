module Request.Investigator exposing (get, list)

import Data.Investigator as Investigator exposing (Investigator)
import Http
import HttpBuilder exposing (RequestBuilder, withExpect, withQueryParams)
import Json.Decode as Decode
import Json.Encode as Encode
import Json.Encode.Extra as EncodeExtra


host : String
host =
    -- "https://www.imicrobe.us
    "http://localhost:3006"



-- list : Http.Request (List Investigator)


list =
    let
        -- "https://www.imicrobe.us/investigator/list.json"
        url =
            host ++ "/investigators"

        decoder =
            -- Decode.list (Decode.dict Decode.string)
            Decode.list Investigator.decoder
    in
    HttpBuilder.get url
        |> HttpBuilder.withExpect (Http.expectJson decoder)
        |> HttpBuilder.toRequest



-- get : Int -> Http.Request Profile


get id =
    let
        url =
            -- host ++ investigator/view/" ++ toString id ++ ".json"
            host ++ "/investigators/" ++ toString id

        decoder =
            -- Decode.dict Decode.string
            Investigator.decoder
    in
    HttpBuilder.get url
        |> HttpBuilder.withExpect (Http.expectJson decoder)
        |> HttpBuilder.toRequest

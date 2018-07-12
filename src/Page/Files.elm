module Page.Files exposing (Model, Msg, init, update, view)

import Data.Session as Session exposing (Session)
import Data.Sample as Sample exposing (Sample, SampleFile)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Http
import Request.Sample
import Request.SampleGroup
import Page.Error as Error exposing (PageLoadError)
import Task exposing (Task)
import Route
import Table exposing (defaultCustomizations)
import Set
import Util exposing ((=>))
import Config exposing (dataCommonsUrl)
import View.Widgets



---- MODEL ----


type alias Model =
    { pageTitle : String
    , tableState : Table.State
    , filterType : String
    , files : List SampleFile
    }


init : Session -> Maybe Int -> Task PageLoadError Model
init session id =
    let
        id_list = -- sample IDs
            session.cart.contents |> Set.toList

        loadSampleFiles =
            case id of
                Nothing -> -- Current
                    if id_list == [] then
                        Task.succeed []
                    else
                        Request.Sample.files session.token id_list |> Http.toTask

                Just id ->
                    Request.SampleGroup.files session.token id |> Http.toTask
    in
    loadSampleFiles
        |> Task.andThen
            (\files ->
                Task.succeed
                    { pageTitle = "Files"
                    , tableState = Table.initialSort "Type"
                    , filterType = "All"
                    , files = files
                    }
            )
            |> Task.mapError Error.handleLoadError



-- UPDATE --


type Msg
    = SetTableState Table.State
    | Filter String


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        SetTableState newState ->
            ( { model | tableState = newState }
            , Cmd.none
            )

        Filter newType ->
            ( { model | filterType = newType }
            , Cmd.none
            )



-- VIEW --


config : Table.Config SampleFile Msg
config =
    Table.customConfig
        { toId = toString << .sample_file_id
        , toMsg = SetTableState
        , columns =
            [ sampleColumn
            , Table.stringColumn "Type" (.file_type << .sample_file_type)
            , fileColumn
            ]
        , customizations =
            { defaultCustomizations | tableAttrs = toTableAttrs }
        }


toTableAttrs : List (Attribute Msg)
toTableAttrs =
    [ attribute "class" "table" ]


sampleColumn : Table.Column SampleFile Msg
sampleColumn =
    Table.veryCustomColumn
        { name = "Sample"
        , viewData = sampleLink
        , sorter = Table.increasingOrDecreasingBy (.sample >> .sample_name >> String.toLower)
        }


sampleLink : SampleFile -> Table.HtmlDetails Msg
sampleLink file =
    Table.HtmlDetails []
        [ a [ Route.href (Route.Sample file.sample_id) ]
            [ text <| Util.truncate file.sample.sample_name ]
        ]


fileColumn : Table.Column SampleFile Msg
fileColumn =
    Table.veryCustomColumn
        { name = "File"
        , viewData = fileLink
        , sorter = Table.increasingOrDecreasingBy (.file >> String.toLower)
        }


fileLink : SampleFile -> Table.HtmlDetails Msg
fileLink file =
    Table.HtmlDetails []
        [ a [ attribute "href" (dataCommonsUrl ++ file.file), target "_blank" ]
            [ text <| file.file ]
        ]


view : Model -> Html Msg
view model =
    div [ class "container" ]
        [ div [ class "row" ]
            [ h1 []
                [ text (model.pageTitle ++ " ")
                , View.Widgets.counter (List.length model.files)
                ]
            , div []
                [ viewFiles model
                ]
            ]
        ]


viewFiles : Model -> Html Msg
viewFiles model =
    let
        filteredFiles =
            List.filter (\f -> (model.filterType == "All" || f.sample_file_type.file_type == model.filterType)) model.files
    in
    if filteredFiles == [] then
        text "No files to show"
    else
        div []
            [ viewToolbar model
            , Table.view config model.tableState filteredFiles
            ]


viewToolbar : Model -> Html Msg
viewToolbar model =
    let
        types =
            Set.toList <| Set.fromList <| List.map (.sample_file_type >> .file_type) model.files

        numTypes =
            List.length types

        btn label =
            button [ class "btn btn-default", onClick (Filter label) ] [ text label ]

        lia label =
            li [] [ a [ onClick (Filter label) ] [ text label ] ]
    in
    if (numTypes < 2) then
        text ""
    else if (numTypes < 10) then
        div [ class "btn-group margin-top-bottom", attribute "role" "group", attribute "aria-label" "..."]
           (btn "All" :: List.map (\t -> btn t) types)
    else
        div [ class "dropdown" ]
            [ button [ class "btn btn-default dropdown-toggle margin-top-bottom", attribute "type" "button", id "dropdownMenu1", attribute "data-toggle" "dropdown", attribute "aria-haspopup" "true", attribute "aria-expanded" "true" ]
                [ text "Filter by Type "
                , span [ class "caret" ] []
                ]
            , ul [ class "dropdown-menu", attribute "aria-labelledby" "dropdownMenu1" ]
                (lia "All" :: List.map (\t -> lia t) types)
            ]
module Page.Apps exposing (Model, Msg, init, update, view)

import Data.App
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onInput)
import Http
import Page.Error as Error exposing (PageLoadError, pageLoadError)
import Request.App
import Route
import Table
import Task exposing (Task)
import Util exposing (truncate)
import View.Page as Page


---- MODEL ----


type alias Model =
    { pageTitle : String
    , apps : List Data.App.App
    , tableState : Table.State
    , query : String
    }


init : Task PageLoadError Model
init =
    let
        -- Load page - Perform tasks to load the resources of a page
        title =
            Task.succeed "Recommended Reading"

        loadApps =
            Request.App.list |> Http.toTask

        tblState =
            Task.succeed (Table.initialSort "Name")

        qry =
            Task.succeed ""

        handleLoadError err =
            -- If a resource task fail load error page
            let
                errMsg =
                    case err of
                        Http.BadStatus response ->
                            case String.length response.body of
                                0 ->
                                    "Bad status"

                                _ ->
                                    response.body

                        _ ->
                            toString err
            in
            Error.pageLoadError Page.Home errMsg
    in
    Task.map4 Model title loadApps tblState qry
        |> Task.mapError handleLoadError



-- UPDATE --


type Msg
    = SetQuery String
    | SetTableState Table.State


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        SetQuery newQuery ->
            ( { model | query = newQuery }
            , Cmd.none
            )

        SetTableState newState ->
            ( { model | tableState = newState }
            , Cmd.none
            )


config : Table.Config Data.App.App Msg
config =
    Table.config
        { toId = toString << .app_id
        , toMsg = SetTableState
        , columns =
            [ nameColumn
            ]
        }


nameColumn : Table.Column Data.App.App Msg
nameColumn =
    Table.veryCustomColumn
        { name = "Name"
        , viewData = nameLink
        , sorter = Table.increasingOrDecreasingBy .app_name
        }


nameLink : Data.App.App -> Table.HtmlDetails Msg
nameLink app =
    Table.HtmlDetails []
        [ a [ Route.href (Route.App app.app_id) ]
            [ text app.app_name ]
        ]



-- VIEW --


view : Model -> Html Msg
view model =
    let
        lowerQuery =
            String.toLower model.query

        acceptableApps =
            List.filter
                (String.contains lowerQuery << String.toLower << .app_name)
                model.apps
    in
    div [ class "container" ]
        [ div [ class "row" ]
            [ h2 [] [ text model.pageTitle ]
            , input [ placeholder "Search by Name", onInput SetQuery ] []
            , Table.view config model.tableState acceptableApps
            ]
        ]

module Page.ProjectGroups exposing (Model, Msg, init, update, view)

import Data.ProjectGroup exposing (ProjectGroup)
import Data.Session exposing (Session)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onInput)
import Http
import Page.Error as Error exposing (PageLoadError)
import Request.ProjectGroup
import Route
import Table
import Task exposing (Task)
import View.Widgets



---- MODEL ----


type alias Model =
    { pageTitle : String
    , projectGroups : List ProjectGroup
    , tableState : Table.State
    , query : String
    }


init : Session -> Task PageLoadError Model
init session =
    let
        -- Load page - Perform tasks to load the resources of a page
        title =
            Task.succeed "Project Groups"

        loadProjectGroups =
            Request.ProjectGroup.list session.token |> Http.toTask

        tblState =
            Task.succeed (Table.initialSort "Name")

        qry =
            Task.succeed ""
    in
    Task.map4 Model title loadProjectGroups tblState qry
        |> Task.mapError Error.handleLoadError



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


config : Table.Config ProjectGroup Msg
config =
    Table.config
        { toId = toString << .project_group_id
        , toMsg = SetTableState
        , columns =
            [ nameColumn
            ]
        }


nameColumn : Table.Column ProjectGroup Msg
nameColumn =
    Table.veryCustomColumn
        { name = "Name"
        , viewData = nameLink
        , sorter = Table.unsortable
        }


nameLink : ProjectGroup -> Table.HtmlDetails Msg
nameLink group =
    Table.HtmlDetails []
        [ a [ Route.href (Route.ProjectGroup group.project_group_id) ]
            [ text group.group_name ]
        ]



-- VIEW --


view : Model -> Html Msg
view model =
    let
        lowerQuery =
            String.toLower model.query

        acceptableGroups =
            List.filter
                (String.contains lowerQuery << String.toLower << .group_name)
                model.projectGroups
    in
    div [ class "container" ]
        [ div [ class "row" ]
            [ h1 []
                [ text (model.pageTitle ++ " ")
                , View.Widgets.counter (List.length acceptableGroups)
                , small [ class "right" ]
                    [ input [ placeholder "Search by Name", onInput SetQuery ] [] ]
                ]
            , Table.view config model.tableState acceptableGroups
            ]
        ]

module Page.Sample exposing (Model, Msg, init, update, view)

import Data.Sample
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onInput)
import FormatNumber exposing (format)
import FormatNumber.Locales exposing (usLocale)
import Http
import Page.Error as Error exposing (PageLoadError)
import Request.Sample
import Route
import Task exposing (Task)
import Config exposing (dataCommonsUrl)
import Table exposing (defaultCustomizations)



---- MODEL ----


type alias Model =
    { pageTitle : String
    , sample_id : Int
    , sample : Data.Sample.Sample
    , tableState : Table.State
    , query : String
    }


init : Int -> Task PageLoadError Model
init id =
    let
        -- Load page - Perform tasks to load the resources of a page
        title =
            Task.succeed "Sample"

        loadSample =
            Request.Sample.get id |> Http.toTask

        tblState =
            Task.succeed (Table.initialSort "Name")

        qry =
            Task.succeed ""
    in
    Task.map5 Model title (Task.succeed id) loadSample tblState qry
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



-- VIEW --


view : Model -> Html Msg
view model =
    div [ class "container" ]
        [ div [ class "row" ]
            [ div [ class "page-header" ]
                [ h1 []
                    [ text (model.pageTitle ++ " ")
                    , small []
                        [ text model.sample.sample_name ]
                    ]
                ]
            , viewSample model.sample
            , viewFiles model.sample.sample_files
            , viewOntologies model.sample.ontologies
            , viewAttributes model
            ]
        ]


viewSample : Data.Sample.Sample -> Html msg
viewSample sample =
    let
        numFiles =
            List.length sample.sample_files

        numOntologies =
            List.length sample.ontologies
    in
    table [ class "table" ]
        [ tr []
            [ th [] [ text "Project" ]
            , td []
                [ a [ Route.href (Route.Project sample.project_id) ] [ text sample.project.project_name ]
                ]
            ]
        , tr []
            [ th [] [ text "Sample" ]
            , td [] [ text sample.sample_name ]
            ]
        , tr []
            [ th [] [ text "Code" ]
            , td [] [ text sample.sample_acc ]
            ]
        , tr []
            [ th [] [ text "Sample Type" ]
            , td [] [ text sample.sample_type ]
            ]
        ]


viewFiles : List Data.Sample.SampleFile2 -> Html msg
viewFiles files =
    let
        numFiles =
            List.length files

        label =
            case numFiles of
                0 ->
                    span [] []

                _ ->
                    span [ class "badge" ]
                        [ text (toString numFiles)
                        ]

        body =
            case numFiles of
                0 ->
                    text "None"

                _ ->
                    table [ class "table" ]
                        (List.map viewFile files)
    in
    div []
        [ h2 []
            [ text "Files "
            , label
            ]
        , body
        ]


viewFile : Data.Sample.SampleFile2 -> Html msg
viewFile file =
    tr []
        [ td []
            [ a [ href (dataCommonsUrl ++ file.file) ] [ text file.file ]
            ]
        ]


viewOntologies : List Data.Sample.Ontology -> Html msg
viewOntologies ontologies =
    let
        numOntologies =
            List.length ontologies

        label =
            case numOntologies of
                0 ->
                    span [] []

                _ ->
                    span [ class "badge" ]
                        [ text (toString numOntologies)
                        ]

        body =
            case numOntologies of
                0 ->
                    text "None"

                _ ->
                    table [ class "table" ]
                        (List.map viewOntology ontologies)
    in
    div []
        [ h2 []
            [ text "Ontologies "
            , label
            ]
        , body
        ]


viewOntology : Data.Sample.Ontology -> Html msg
viewOntology ont =
    let
        display =
            ont.ontology_acc
                ++ (case ont.label of
                        "" ->
                            ""

                        _ ->
                            " (" ++ ont.label ++ ")"
                   )
    in
    tr []
        [ td []
            [ text display
            ]
        ]


attrTableConfig : Table.Config Data.Sample.Attribute Msg
attrTableConfig =
    Table.customConfig
        { toId = toString << .sample_attr_id
        , toMsg = SetTableState
        , columns =
            [ typeColumn
            , aliasColumn
            , valueColumn
            ]
        , customizations =
            { defaultCustomizations | tableAttrs = toTableAttrs }
        }


toTableAttrs : List (Attribute Msg)
toTableAttrs =
    [ attribute "class" "table table-condensed"
    ]


typeColumn : Table.Column Data.Sample.Attribute Msg
typeColumn =
    Table.customColumn
        { name = "Type"
        , viewData = .type_ << .sample_attr_type
        , sorter = Table.increasingOrDecreasingBy (.type_ << .sample_attr_type)
        }


aliasColumn : Table.Column Data.Sample.Attribute Msg
aliasColumn =
    Table.customColumn
        { name = "Aliases"
        , viewData = aliasesToString << .sample_attr_type_aliases << .sample_attr_type
        , sorter = Table.increasingOrDecreasingBy (.type_ << .sample_attr_type)
        }


aliasesToString : List Data.Sample.AttributeTypeAlias -> String
aliasesToString aliases =
    String.join ", " (List.map .alias_ aliases)


valueColumn : Table.Column Data.Sample.Attribute Msg
valueColumn =
    Table.customColumn
        { name = "Value"
        , viewData = .attr_value
        , sorter = Table.increasingOrDecreasingBy .attr_value
        }


viewAttributes : Model -> Html Msg
viewAttributes model =
    let
        query =
            model.query

        lowerQuery =
            String.toLower query

        attrFilter attr =
            ( (String.contains lowerQuery (String.toLower attr.attr_value))
                || (String.contains lowerQuery (aliasesToString attr.sample_attr_type.sample_attr_type_aliases |> String.toLower))
                || (String.contains lowerQuery (String.toLower attr.sample_attr_type.type_)) )

        acceptableAttributes =
            List.filter attrFilter model.sample.sample_attrs

        numShowing =
            let
                myLocale =
                    { usLocale | decimals = 0 }

                count =
                    List.length acceptableAttributes

                numStr =
                    count |> toFloat |> format myLocale
            in
            case count of
                0 ->
                    span [] []

                _ ->
                    span [ class "badge" ]
                        [ text numStr ]
        display =
            case acceptableAttributes of
                [] ->
                    text "None"

                _ ->
                    Table.view attrTableConfig model.tableState acceptableAttributes

    in
    div [ class "container" ]
        [ div [ class "row" ]
            [ h2 []
                [ text "Attributes "
                , numShowing
                , small [ class "right" ]
                    [ input [ placeholder "Search", onInput SetQuery ] [] ]
                ]
            , display
            ]
        ]